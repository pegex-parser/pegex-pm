use Pegex;

my $grammar = <<'...';
expr: add-sub
add-sub: mul-div+ % /~([<PLUS><DASH>])~/
mul-div: exp+ % /~([<STAR><SLASH>])~/
exp: token+ % /~<CARET>~/
token: /~<LPAREN>~/ expr /~<RPAREN>~/ | number
number: /~(<DASH>?<DIGIT>+)~/
...

{
    package Calculator;
    use base 'Pegex::Tree';

    sub got_add_sub {
        my ($self, $list) = @_;
        $self->flatten($list);
        while (@$list > 1) {
            my ($a, $op, $b) = splice(@$list, 0, 3);
            unshift @$list, ($op eq '+') ? ($a + $b) : ($a - $b);
        }
        @$list;
    }

    sub got_mul_div {
        my ($self, $list) = @_;
        $self->flatten($list);
        while (@$list > 1) {
            my ($a, $op, $b) = splice(@$list, 0, 3);
            unshift @$list, ($op eq '*') ? ($a * $b) : ($a / $b);
        }
        @$list;
    }

    sub got_exp {
        my ($self, $list) = @_;
        $self->flatten($list);
        while (@$list > 1) {
            my ($a, $b) = splice(@$list, -2, 2);
            push @$list, $a ** $b;
        }
        @$list;
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
    my $calculator = pegex($grammar, 'Calculator');
    my $result = eval { $calculator->parse($expr) };
    print $@ || "$expr = $result\n";
}

# calc '2';
# calc '2 * 4';
# calc '2 * 4 + 6';
# calc '2 + 4 * 6 + 1';
# calc '2 + (4 + 6) * 8';
# calc '(((2 + (((4 + (6))) * (8)))))';
# calc '2 ^ 3 ^ 2';
# calc '2 ^ (3 ^ 2)';
# calc '2 * 2^3^2';
# calc '(2^5)^2';
# calc '2^5^2';
# calc '0*1/(2+3)-4^5';
# calc '2/3+1';
