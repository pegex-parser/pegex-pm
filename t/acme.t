use Test::More tests => 1;

use Parse::Pegex;
use Parse::Pegex::Compiler;

my $p = Parse::Pegex->new(stream => 'abc');

is $p->stream, 'abc', 'Parse::Pegex OO works';
