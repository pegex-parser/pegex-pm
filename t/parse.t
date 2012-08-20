# $Pegex::Parser::Debug = 1;

use Test::More tests => 1;

use Pegex;

$grammar_file = 't/mice.pgx';
open GRAMMAR, $grammar_file
    or die "Can't open '$grammar_file' for input";
$grammar = do {local $/; <GRAMMAR>};

eval { pegex($grammar)->parse("3 blind mice\n") }; $@
? fail $@
: pass "!<rule> works";
