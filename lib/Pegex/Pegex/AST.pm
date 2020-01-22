package Pegex::Pegex::AST;
use Pegex::Base;
extends 'Pegex::Tree';

use Pegex::Grammar::Atoms;

has atoms => Pegex::Grammar::Atoms->new->atoms;
has extra_rules => {};

sub got_grammar {
    my ($self, $got) = @_;
    my ($meta_section, $rule_section) = @$got;
    my $grammar = {
        '+toprule' => $self->{toprule},
        %{$self->{extra_rules}},
        %$meta_section,
    };
    for my $rule (@$rule_section) {
        my ($key, $value) = %$rule;
        $grammar->{$key} = $value;
    }
    return $grammar;
}

sub got_meta_section {
    my ($self, $got) = @_;
    my $meta = {};
    for my $next (@$got) {
        my ($key, $val) = @$next;
        $key = "+$key";
        my $old = $meta->{$key};
        if (defined $old) {
            if (ref $old) {
                push @$old, $val;
            }
            else {
                $meta->{$key} = [ $old, $val ];
            }
        }
        else {
            $meta->{$key} = $val;
        }
    }
    return $meta;
}

sub got_rule_definition {
    my ($self, $got) = @_;
    my ($name, $value) = @$got;
    $name =~ s/-/_/g;
    $self->{toprule} = $name if $name eq 'TOP';
    $self->{toprule} ||= $name;
    return +{ $name => $value };
}

sub got_bracketed_group {
    my ($self, $got) = @_;
    my ($prefix, $group, $suffix) = @$got;
    set_modifier($group, $prefix);
    set_quantity($group, $suffix);
    return $group;
}

sub got_all_group {
    my ($self, $got) = @_;
    my $list = $self->get_group($got);
    die unless @$list;
    return $list->[0] if @$list == 1;
    return { '.all' => $list };
}

sub got_any_group {
    my ($self, $got) = @_;
    my $list = $self->get_group($got);
    die unless @$list;
    return $list->[0] if @$list == 1;
    return { '.any' => $list };
}

sub get_group {
    my ($self, $group) = @_;
    sub get {
        my $it = shift;
        my $ref = ref($it) or return;
        if ($ref eq 'HASH') {
            return($it || ());
        }
        elsif ($ref eq 'ARRAY') {
            return map get($_), @$it;
        }
        else {
            die;
        }
    };
    return [ get($group) ];
}

sub got_rule_part {
    my ($self, $got) = @_;
    my ($rule, $sep) = @$got;
    $rule = set_separator($rule, @$sep) if @$sep;
    return $rule;
}

sub got_rule_reference {
    my ($self, $got) = @_;
    my ($prefix, $ref1, $ref2, $suffix) = @$got;
    my $ref = $ref1 || $ref2;
    $ref =~ s/-/_/g;
    my $node = +{ '.ref' => $ref };
    if (my $regex = $self->atoms->{$ref}) {
        $self->{extra_rules}{$ref} = +{ '.rgx' => $regex };
    }
    set_modifier($node, $prefix);
    set_quantity($node, $suffix);
    return $node;
}

sub got_quoted_regex {
    my ($self, $got) = @_;
    $got =~ s/([^\w\`\%\:\<\/\,\=\;])/\\$1/g;
    return +{ '.rgx' => $got };
}

sub got_regex_rule_reference {
    my ($self, $got) = @_;
    my $ref = $got->[0] || $got->[1];
    return +{ '.ref' => $ref };
}

sub got_whitespace_maybe {
    my ($self) = @_;
    return +{ '.rgx' => '<_>'};
}

sub got_whitespace_must {
    my ($self) = @_;
    return +{ '.rgx' => '<__>'};
}

sub got_whitespace_start {
    my ($self, $got) = @_;
    my $rule = $got eq '+' ? '__' : '_';
    return +{ '.rgx' => "<$rule>"};
}

sub got_regular_expression {
    my ($self, $got) = @_;
    my $modifier = shift @$got;
    if (@$got == 2) {
        my $part = shift @$got;
        unshift @{$got->[0]}, $part;
    }

    my $regex = join '', map {
        if (ref($_)) {
            my $part;
            if (defined($part = $_->{'.rgx'})) {
                $part;
            }
            elsif (defined($part = $_->{'.ref'})) {
                "<$part>";
            }
            else {
                XXX $_;
            }
        }
        else {
            $_;
        }
    } @{$got->[0]};
    # $regex =~ s!\(([ism]?\:|\=|\!)!(?$1!g;
    $regex =~ s{\(([ism]?\:|\=|\!|<[=!])}{(?$1}g;
    my $rgx = { '.rgx' => $regex };
    set_modifier($rgx, $modifier) if $modifier;
    return $rgx;
}

sub got_whitespace_token {
    my ($self, $got) = @_;
    my $token;
    if ($got =~ /^\~{1,2}$/) {
        $token = +{ '.ref' => ('_' x length($got)) };
    }
    elsif ($got =~ /^\-{1,2}$/) {
        $token = +{ '.ref' => ('_' x length($got)) };
    }
    elsif ($got eq '+') {
        $token = +{ '.ref' => '__' };
    }
    else {
        die;
    }
    return $token;
}

sub got_error_message {
    my ($self, $got) = @_;
    return +{ '.err' => $got };
}

sub set_modifier {
    my ($object, $modifier) = @_;
    return unless $modifier;
    if ($modifier eq '=') {
        $object->{'+asr'} = 1;
    }
    elsif ($modifier eq '!') {
        $object->{'+asr'} = -1;
    }
    elsif ($modifier eq '.') {
        $object->{'-skip'} = 1;
    }
    elsif ($modifier eq '+') {
        $object->{'-wrap'} = 1;
    }
    elsif ($modifier eq '-') {
        $object->{'-flat'} = 1;
    }
    else {
        die "Invalid modifier: '$modifier'";
    }
}

sub set_quantity {
    my ($object, $quantity) = @_;
    return unless $quantity;
    if ($quantity eq '?') {
        $object->{'+max'} = 1;
    }
    elsif ($quantity eq '*') {
        $object->{'+min'} = 0;
    }
    elsif ($quantity eq '+') {
        $object->{'+min'} = 1;
    }
    elsif ($quantity =~ /^(\d+)$/) {
        $object->{'+min'} = int $1 + 0;
        $object->{'+max'} = int $1 + 0;
    }
    elsif ($quantity =~ /^(\d+)-(\d+)$/) {
        $object->{'+min'} = int $1 + 0;
        $object->{'+max'} = int $2 + 0;
    }
    elsif ($quantity =~ /^(\d+)\+$/) {
        $object->{'+min'} = int $1 + 0;
    }
    else {
        die "Invalid quantifier: '$quantity'";
    }
}

sub set_separator {
    my ($rule, $op, $sep) = @_;
    my $extra = ($op eq '%%');
    if (not defined $rule->{'+max'} and not defined $rule->{'+min'}) {
        $rule = {'.all' => [ $rule, {%{clone($sep)}, '+max' => 1}, ] }
            if $extra;
        return $rule;
    }
    elsif (defined $rule->{'+max'} and defined $rule->{'+min'}) {
        my ($min, $max) = delete @{$rule}{qw(+min +max)};
        $min-- if $min > 0;
        $max-- if $max > 0;
        $rule = {
            '.all' => [
                $rule,
                {
                    '+min' => $min,
                    '+max' => $max,
                    '-flat' => 1,
                    '.all' => [
                        $sep,
                        clone($rule),
                    ],
                },
            ],
        };
    }
    elsif (not defined $rule->{'+max'}) {
        my $copy = clone($rule);
        my $min = delete $copy->{'+min'};
        my $new = {
            '.all' => [
                $copy,
                {
                    '+min' => 0,
                    '-flat' => 1,
                    '.all' => [
                        $sep,
                        clone($copy),
                    ],
                },
            ],
        };
        if ($rule->{'+min'} == 0) {
            $rule = $new;
            $rule->{'+max'} = 1;
        }
        elsif ($rule->{'+min'} == 1) {
            $rule = $new;
        }
        else {
            $rule = $new;
            $min-- if $min > 0;
            $rule->{'.all'}[-1]{'+min'} = $min;
        }
    }
    else {
        if ($rule->{'+max'} == 1) {
            delete $rule->{'+min'};
            $rule = {
                %{clone($rule)},
                '+max' => 1,
            };
            if ($extra) {
                $rule = { '.all' => [$rule, {%{clone($sep)}, '+max' => 1}] };
            }
            return $rule;
        }
        else {
            XXX 'FAIL', $rule, $op, $sep;
        }
    }
    if ($extra) {
        push @{$rule->{'.all'}}, {%{clone($sep)}, '+max' => 1};
    }
    return $rule;
}

sub clone {
    my ($o) = @_;
    return ref($o) eq 'HASH'
    ? { map { my $v = $o->{$_}; ($_, (ref($v) ? clone($v) : $v)) } keys %$o }
    : [ map { ref($_) ? clone($_) : $_ } @$o ];
}

1;
