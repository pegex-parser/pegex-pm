use strict;
use warnings;

use Test::More;

# 2015-02-03 Safe.pm fails to load on Travis + 5.14
BEGIN {
    if ($ENV{TRAVIS} eq 'true' and $ENV{TRAVIS_PERL_VERSION} eq '5.14') {
        plan skip_all => 'Travis/Safe/5.14';
    }
}

use Safe;

BEGIN { Safe->new }

use Pegex;

pegex('a: /a/')->parse('a');

pass 'GitHub ingydotnet/jsony-pm issue #2 fixed';

done_testing;
