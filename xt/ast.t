# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use Test::More;

plan skip_all => 'not ready yet';

plan tests => 1;


use Pegex::Grammar;
use XXX -with => 'YAML::XS';

my $pegex_grammar_file = '../pegex-pgx/pegex.pgx';

my $grammar = Pegex::Grammar->new(
    text => $pegex_grammar_file,
#     parser => 'Pegex::Parser',
#     receiver => 'Pegex::Compiler::AST',
    parser => 'Pegex::Parser2',
    receiver => 'Pegex::AST2',
);

XXX $grammar->parse($pegex_grammar_file);
