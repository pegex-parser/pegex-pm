use Test::More;

use Pegex;

my $parser = pegex('a: /(x+)/');
is $parser->parse('xxxx')->{a}, 'xxxx',
    'First parse works';

is $parser->completed, 1,
    '$parser->complete works';

$parser->reset;
$parser->{debug} = 0;

$parser->{xxx} = 2;
is $parser->parse('xxxxxxxx')->{a}, 'xxxxxxxx',
    'Second parse works';

done_testing;
