package Pegex::Pegex::AST;

use Pegex::Base;
extends 'Pegex::Tree';

use Pegex::Grammar::Atoms;

has atoms => Pegex::Grammar::Atoms->new->atoms;
has extra_rules => {};
has prefixes => {
    '!' => ['+asr', -1],
    '=' => ['+asr', 1],
    '.' => '-skip',
    '-' => '-pass',
    '+' => '-wrap',
  };

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
    if ($prefix) {
        $group->{$self->prefixes->{$prefix}} = 1;
    }
    if ($suffix) {
        $self->set_quantity($group, $suffix);
    }
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
    my ($rule, $sep_op, $sep_rule) = @$got;
    if ($sep_rule) {
        $sep_rule->{'+eok'} = 1 if $sep_op eq '%%';
        $rule->{'.sep'} = $sep_rule;
    }
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
    if ($suffix) {
        $self->set_quantity($node, $suffix);
    }
    if ($prefix) {
        my ($key, $val) = ($self->prefixes->{$prefix}, 1);
        ($key, $val) = @$key if ref $key;
        $node->{$key} = $val;
    }
    return $node;
}

sub got_regular_expression {
    my ($self, $got) = @_;
    # replace - or + with space next to it
    $got =~ s/(?:^|\s)(\-+)(?:\s|$)/${\ ('<' . '_' x length($1) . '>') }/ge;
    $got =~ s/(?:^|\s)(\++)(?:\s|$)/${\ ('<' . '__' x length($1) . '>') }/ge;
    $got =~ s/\s*#.*\n//g;
    $got =~ s/\s+//g;
    $got =~ s!\(([ism]?\:|\=|\!)!(?$1!g;
    return +{ '.rgx' => $got };
}

sub got_whitespace_token {
    my ($self, $got) = @_;
    my $token;
    if ($got =~ /^\~+$/) {
        $token = +{ '.rgx' => "<ws${\ length($got)}>" };
    }
    elsif ($got =~ /^\-+$/) {
        $token = +{ '.ref' => ('_' x length($got)) };
    }
    elsif ($got =~ /^\++$/) {
        $token = +{ '.ref' => ('__' x length($got)) };
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

sub set_quantity {
    my ($self, $object, $quantifier) = @_;
    if ($quantifier eq '*') {
        $object->{'+min'} = 0;
    }
    elsif ($quantifier eq '+') {
        $object->{'+min'} = 1;
    }
    elsif ($quantifier eq '?') {
        $object->{'+max'} = 1;
    }
    elsif ($quantifier =~ /^(\d+)\+$/) {
        $object->{'+min'} = $1;
    }
    elsif ($quantifier =~ /^(\d+)\-(\d+)+$/) {
        $object->{'+min'} = $1;
        $object->{'+max'} = $2;
    }
    elsif ($quantifier =~ /^(\d+)$/) {
        $object->{'+min'} = $1;
        $object->{'+max'} = $1;
    }
    else { die "Invalid quantifier: '$quantifier'" }
}

1;
