use 5.10.0;
use Test::More;

use Pegex;

my $parser = pegex('a: /<ANY>*?(x+)<ANY>*/');
is $parser->parse('xxxx')->{a}, 'xxxx',
    'First parse works';

is $parser->parse('xxxx')->{a}, 'xxxx',
    'Second parse works';

done_testing;
