##
# name:      Pegex::Compiler::AST
# abstract:  Pegex Compiler AST
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler::AST;
use Pegex::Mo;
extends 'Pegex::Receiver';

use Pegex::Grammar::Atoms;

has 'top';
has 'extra_rules' => default => sub {+{}};

my %prefixes = (
    '!' => ['+asr', -1],
    '=' => ['+asr', 1],
    '.' => '-skip',
    '-' => '-pass',
);

# Uncomment this to debug. See entire raw AST.
# sub final {
#     my ($self, $match) = @_;
#     XXX $match;
# }
# 
# __END__


sub got_grammar {
    my ($self, $rules) = @_;
    my $grammar = {
        '+top' => $self->top,
        %{$self->extra_rules},
    };
    for (@$rules) {
        my ($key, $value) = %$_;
        $grammar->{$key} = $value;
    }
    return $grammar;
}

sub got_rule_definition {
    my ($self, $match) = @_;
    my $name = $match->[0]{rule_name}{1};
    $self->{top} = $name if $name eq 'TOP';
    $self->{top} ||= $name;
    my $value = $match->[1]{rule_group};
    return +{ $name => $value };
}

sub got_bracketed_group {
    my ($self, $match) = @_;
    my $group = $match->[1]{rule_group};
    if (my $prefix = $match->[0]{1}) {
        $group->{$prefixes{$prefix}} = 1;
    }
    if (my $qty = $match->[2]{1}) {
        $group->{'+qty'} = $qty;
    }
    return $group;
}

sub got_all_group {
    my ($self, $match) = @_;
    my $list = $self->get_group($match);
    die unless @$list;
    return $list->[0] if @$list == 1;
    return { '.all' => $list };
}

sub got_any_group {
    my ($self, $match) = @_;
    my $list = $self->get_group($match);
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
            return($it->{rule_item} || ());
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
    my ($self, $part) = @_;
    my ($rule, $sep) = @$part;
    if ($sep) {
        $rule->{rule_item}{'.sep'} = $sep->[0]{rule_item};
    }
    return $rule;
}

sub got_rule_reference {
    my ($self, $match) = @_;
    my ($prefix, $ref, $suffix) =
        @{$match}{qw(1 2 3)};
    my $node = +{ '.ref' => $ref };
    if (my $regex = Pegex::Grammar::Atoms->atoms->{$ref}) {
        $self->extra_rules->{$ref} = +{ '.rgx' => $regex };
    }
    $node->{'+qty'} = $suffix if $suffix;
    if ($prefix) {
        my ($key, $val) = ($prefixes{$prefix}, 1);
        ($key, $val) = @$key if ref $key;
        $node->{$key} = $val;
    }
    return $node;
}

sub got_regular_expression {
    my ($self, $match) = @_;
    return +{ '.rgx' => $match->{1} };
}

sub got_error_message {
    my ($self, $match) = @_;
    return +{ '.err' => $match->{1} };
}

1;
