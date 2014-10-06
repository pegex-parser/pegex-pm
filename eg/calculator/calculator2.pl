use strict;
use FindBin;
use lib "$FindBin::Bin/lib";

use Pegex;
use Runner;

my $grammar = <<'...';
expr: operand (operator operand)*
operator: /- (['+-*/^'])/
operand: num | /- '('/ expr /- ')'/
num: /- ('-'? DIGIT+)/
...

{
    package Calculator;
    use base 'Pegex::Tree', 'Precedence';

    my $operator_precedence_table = {
        '+' => {p => 1, a => 'l'},
        '-' => {p => 1, a => 'l'},
        '*' => {p => 2, a => 'l'},
        '/' => {p => 2, a => 'l'},
        '^' => {p => 3, a => 'r'},
    };

    sub got_expr {
        my ($self, $expr) = @_;
        $self->precedence_rpn($expr, $operator_precedence_table);
    }
}

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
    elsif ($expr->[-1] =~ m!^[-+*/^]$!) {
        evaluate($expr);
    }
    else {
        pop @$expr;
    }
}

Runner->new(args => \@ARGV)->run(
    sub { evaluate(pegex($grammar, 'Calculator')->parse($_[0])) }
);
