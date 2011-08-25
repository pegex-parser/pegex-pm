##
# name:      Pegex::Compiler::AST
# abstract:  Pegex Compiler AST
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler::AST;
use Pegex::Receiver -base;

has 'stack' => [];

sub got_rule_name {
    my $self = shift;
    my $name = shift;
    $self->data->{_FIRST_RULE} ||= $name;
    push @{$self->stack}, [$name];
}

sub got_rule_definition {
    my $self = shift;
    $self->data->{$self->stack->[0]->[0]} = $self->stack->[0]->[1];
    $self->stack([]);
}

sub got_regular_expression {
    my $self = shift;
    my $re = shift;
    push @{$self->stack->[-1]}, {'+re' => $re};
}

sub try_any_group {
    my $self = shift;
    push @{$self->stack}, {'+any' => []};
}
sub not_any_group {
    my $self = shift;
    pop @{$self->stack};
}

sub try_all_group {
    my $self = shift;
    push @{$self->stack}, {'+all' => []};
}
sub not_all_group {
    my $self = shift;
    pop @{$self->stack};
}

sub got_rule_group {
    my $self = shift;
    my $group = pop @{$self->stack};
    push @{$self->stack->[-1]}, $group;
}

sub got_rule_reference {
    my $self = shift;
    my ($modifier, $name, $quantifier) = @_;
    my $rule =
        $modifier eq '!' ?
            { '+not' => $name } :
            { '+rule' => $name };
    $rule->{'<'} = $quantifier if $quantifier;
    my $current = $self->stack->[-1];
    # A single reference
    if (ref $current ne 'HASH') {
        push @{$self->stack->[-1]}, $rule;
    }
    # An 'all' group
    elsif ($current->{'+all'}) {
        push @{$current->{'+all'}}, $rule;
    }
    # An 'any' group
    elsif ($current->{'+any'}) {
        push @{$current->{'+any'}}, $rule;
    }
}

1;
