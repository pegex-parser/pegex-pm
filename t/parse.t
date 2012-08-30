# $Pegex::Parser::Debug = 1;

use Test::More tests => 1;

use Pegex;
use Pegex::Input;

$grammar_file = 't/mice.pgx';

eval { pegex( Pegex::Input->new(file => $grammar_file) )->parse("3 blind mice\n") }; $@
? fail $@
: pass "!<rule> works";
