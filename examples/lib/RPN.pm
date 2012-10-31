use strict;
package RPN;

sub evaluate {
    my ($expr) = @_;
    return $expr->[0] if @$expr == 1;
    my $op = pop @$expr;
    my $b = get_value($expr);
    my $a = get_value($expr);
    return
        $op eq '+' ? $a + $b :
        $op eq '-' ? $a - $b :
        $op eq '*' ? $a * $b :
        $op eq '/' ? $a / $b :
        $op eq '^' ? $a ** $b :
        die "Unknown operator '$op'";
}

sub get_value {
    my ($expr) = @_;
    if (ref($expr->[-1]) eq 'ARRAY') {
        evaluate(pop @$expr);
    }
    elsif ($expr->[-1] =~ m![-+*/^]!) {
        evaluate($expr);
    }
    else {
        pop @$expr;
    }
}

1;
