use strict;
use FindBin;
use lib "$FindBin::Bin/lib";

use Pegex;
use Runner;

my $grammar = <<'...';
# Precedence Climbing grammar:
expr: add-sub
add-sub: mul-div+ % /- ( [ '+-' ])/
mul-div: power+ % /- ([ '*/' ])/
power: token+ % /- '^' /
token: /- '(' -/ expr /- ')'/ | number
number: /- ( '-'? DIGIT+ )/
...

{
    package Calculator;
    use base 'Pegex::Tree';

    sub gotrule {
        my ($self, $list) = @_;
        return $list unless ref $list;

        # Right associative:
        if ($self->rule eq 'power') {
            while (@$list > 1) {
                my ($a, $b) = splice(@$list, -2, 2);
                push @$list, $a ** $b;
            }
        }
        # Left associative:
        else {
            while (@$list > 1) {
                my ($a, $op, $b) = splice(@$list, 0, 3);
                unshift @$list,
                    ($op eq '+') ? ($a + $b) :
                    ($op eq '-') ? ($a - $b) :
                    ($op eq '*') ? ($a * $b) :
                    ($op eq '/') ? ($a / $b) :
                    die;
            }
        }
        return @$list;
    }
}

Runner->new(args => \@ARGV)->run(
    sub { pegex($grammar, 'Calculator')->parse($_[0]) }
);
