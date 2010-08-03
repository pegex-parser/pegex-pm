use Test::More tests => 1;

use Parse::Pegex;

my $p = Parse::Pegex->new(stream => 'abc');

is $p->stream, 'abc', 'Parse::Pegex OO works';
