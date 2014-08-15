use Test::More;

use Safe;

BEGIN { Safe->new }

use Pegex;

pegex('a: /a/')->parse('a');

pass 'GitHub ingydotnet/jsony-pm issue #2 fixed';

done_testing;
