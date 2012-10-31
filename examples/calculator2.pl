use strict;
use FindBin;
use lib "$FindBin::Bin/lib";

use Pegex;
use RPN;

my $grammar = <<'...';
expr: operand (operator operand)*
operator: /~([<PLUS><DASH><STAR><SLASH><CARET>])~/
operand: num | /~<LPAREN>~/ expr /~<RPAREN>~/
num: /~(<DASH>?<DIGIT>+)~/
...

{
    package Calculator;
    use base 'Pegex::Receiver', 'Precedence';

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

while (1) {
    print "\nEnter an equation: ";
    my $input = <>;
    chomp $input;
    last unless length $input;
    calc($input);
}

sub calc {
    my $expr = shift;
    my $calculator = pegex($grammar, receiver => 'Calculator');
    my $rpn = eval { $calculator->parse($expr) };
    my $result = RPN::evaluate($rpn);
    print $@ || "$expr = $result\n";
}
