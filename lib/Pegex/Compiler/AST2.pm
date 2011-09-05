##
# name:      Pegex::Compiler::AST
# abstract:  Pegex Compiler AST
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler::AST2;
use Pegex::AST2 -base;

use Pegex::Grammar::Atoms;

has 'top';
# has 'atoms' => -init => 'Pegex::Grammar::Atoms->atoms';

sub got_grammar {
    my ($self, $match) = @_;
    my $grammar = { '+top' => $self->top };
    my $list = $match->{grammar} or XXX $match;
    for (@$list) {
        my ($key, $value) = %$_;
        $grammar->{$key} = $value;
    }
    return $grammar;
}

sub got_rule_definition {
    my ($self, $match) = @_;
    WWW $match;
    my $name = $match->{rule_definition}[0]{rule_name} or XXX $match;
    my $group = $match->{rule_definition}[1]{rule_group} or XXX $match;
#     XXX $group if $name eq 'document';
    $self->top($name) unless $self->top;
    return +{ $name => $group };
}

# sub got_all_group {
#     my ($self, $match) = @_;
#     WWW $match;
#     my ($group) = values %$match;
#     return $group unless ref($group) eq 'ARRAY';
#     my $list = [ map { ref eq 'ARRAY' ? @$_ : $_ } @$group ];
#     my $return = { '.all' => $list };
#     return $return;
# }

sub got_any_group {
    my ($self, $match) = @_;
    my ($group) = values %$match;
    return +{ '.any' => $group };
}

sub got_rule_reference {
    my ($self, $match) = @_;
    my ($list) = values %$match;
    my ($assertion, $ref, $quantifier) = @$list;
    my $node = +{ '.ref' => $ref };
    if (my $mod = $assertion || $quantifier) {
        $node->{'+mod'} = $mod;
    }
    return $node;
}

sub got_regular_expression {
    my ($self, $match) = @_;
    my ($re) = values %$match;
    return +{ '.re' => $re };
}

sub got_error_message {
    my ($self, $match) = @_;
    my ($error) = values %$match;
    return +{ '.err' => $error };
}

sub got_rule_item {
    my ($self, $match) = @_;
    my ($item) = values %$match;
    return $item;
}

1;
