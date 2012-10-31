use strict;
use FindBin;
use lib "$FindBin::Bin/lib";

use Pegex;

my $grammar = <<'...';
expr: operand (operator operand)*
operator: /~([<PLUS><DASH><STAR><SLASH><CARET>])~/
operand: num | /~<LPAREN>~/ expr /~<RPAREN>~/
num: /~(<DASH>?<DIGIT>+)~/
...

{
    package Calculator;
    use base 'Pegex::Receiver', 'Precedence';
    use RPN;

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

    sub final {
        my ($self, $rpn) = @_;
        RPN::evaluate($rpn);
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
    my $result = eval { $calculator->parse($expr) };
    print $@ || "$expr = $result\n";
}
