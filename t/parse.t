use Test::More tests => 1;

use Pegex;

eval { pegex('t/mice.pgx')->parse("3 blind mice\n") }; $@
? fail $@
: pass "!<rule> works";
