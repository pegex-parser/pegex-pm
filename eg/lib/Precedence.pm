use strict;
package Precedence;

sub precedence_rpn {
    my ($self, $expr, $table) = @_;
    my $tail = pop @$expr;
    for my $elem (@$tail) {
        push @$expr, @$elem;
    }
    my ($out, $ops) = ([], []);
    push @$out, shift @$expr;
    while (@$expr) {
        my $op = shift @$expr;
        my ($p, $a) = @{$table->{$op}}{'p', 'a'};
        while (@$ops) {
            my $p2 = $table->{$ops->[0]}{p};
            last if $p > $p2 or $p == $p2 and $a eq 'r';
            push @$out, shift @$ops;
        }
        unshift @$ops, $op;
        push @$out, shift @$expr;
    }
    $self->flatten([@$out, @$ops]);
}

1;
