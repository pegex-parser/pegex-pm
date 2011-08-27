##
# name:      Pegex::Compiler::AST
# abstract:  Pegex Compiler AST
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler::AST;
use Pegex::Receiver -base;

has 'name';
has 'body';

# Starting a new rule:
sub got_rule_name {
    my ($self, $name) = @_;
    $self->data->{'+top'} ||= $name;
    $self->name($name);
    $self->body([[]]);
}

# Rule is now complete. Finish up rule and add it to data.
sub got_rule_group {
    my ($self, $name) = @_;
#     $self->data->{$self->name} = $self->body; # XXX Debugging
    $self->data->{$self->name} = $self->body->[0][0];
}

# Handle Groups
sub try_all_group {
    my $self = shift;
    push @{$self->body}, ['.all'];
}

sub end_all_group {
    my ($self, $got) = @_;
    my $array = pop @{$self->body};
    return unless $got;
    my $key = shift @$array;
    return unless @$array;
    push @{$self->{body}[-1]}, (@$array > 1)
    ? {$key => $array}
    : $array->[0];
}

sub try_any_group {
    my $self = shift;
    push @{$self->body}, ['.any'];
}

sub end_any_group {
    my ($self, $got) = @_;
    my $array = pop @{$self->body};
    return unless $got;
#     XXX $self, $array;
    my $key = shift @$array;
    push @{$self->{body}[-1]}, {$key => $array};
}

sub try_bracketed_group {
    my $self = shift;
    push @{$self->body}, [];
}

sub end_bracketed_group {
    my ($self, $got) = @_;
    my $item = pop @{$self->body};
    return unless $got;
    return unless @$item;
    $item = $item->[0]
        unless @$item > 1;
    push @{$self->body->[-1]}, $item;
}

sub got_rule_reference {
    my ($self, $pre, $name, $post) = @_;
    my $ref = {
        '.rul' => $name,
        $pre ? ('+mod' => $pre) : $post? ('+mod' => $post) : (),
    };
    push @{$self->{body}[-1]}, $ref;
}

sub got_regular_expression {
    my ($self, $regex)  = @_;
    my $rgx = {
        '.rgx' => $regex,
    };
    push @{$self->{body}[-1]}, $rgx;
}

sub got_error_message {
    my ($self, $error)  = @_;
    my $rgx = {
        '.err' => $error,
    };
    push @{$self->{body}[-1]}, $rgx;
}

__END__
sub got_rule_name {
    my $self = shift;
    my $name = shift;
    $self->data->{'+top'} ||= $name;
    push @{$self->stack}, [$name];
}

sub got_rule_definition {
    my $self = shift;
    $self->data->{$self->stack->[0]->[0]} = $self->stack->[0]->[1];
    $self->stack([]);
}

sub got_regular_expression {
    WWW my $self = shift;
    my $re = shift;
    push @{$self->stack->[-1]}, {'.rgx' => $re};
}

sub try_any_group {
    my $self = shift;
    push @{$self->stack}, {'.any' => []};
}
sub not_any_group {
    my $self = shift;
    pop @{$self->stack};
}

sub try_all_group {
    my $self = shift;
    push @{$self->stack}, {'.all' => []};
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
    my $rule = { '.rul' => $name };
    $rule->{'+mod'} = $quantifier if $quantifier;
    $rule->{'+mod'} = $modifier if $modifier;
    my $current = $self->stack->[-1];
    # A single reference
    if (ref $current ne 'HASH') {
        push @{$self->stack->[-1]}, $rule;
    }
    # An 'all' group
    elsif ($current->{'.all'}) {
        push @{$current->{'.all'}}, $rule;
    }
    # An 'any' group
    elsif ($current->{'.any'}) {
        push @{$current->{'.any'}}, $rule;
    }
}

1;
