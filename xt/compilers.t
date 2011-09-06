# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex::Compiler2;
use Pegex::Compiler::Bootstrap;
use IO::All;
use YAML::XS;

sub pegex_compile {
    my $grammar_text = io((shift)->value)->all;
    Pegex::Compiler2->new->parse($grammar_text)->tree;
}

sub bootstrap_compile {
    my $grammar_text = io((shift)->value)->all;
    Pegex::Compiler::Bootstrap->new->parse($grammar_text)->tree;
}

sub yaml {
    return YAML::XS::Dump((shift)->value);
}

__DATA__
%TestML 1.0

Plan = 3;

test = (grammar) { 
    Label = '$BlockLabel - Does the compiler output match the bootstrap?';
    grammar.pegex_compile.yaml == grammar.bootstrap_compile.yaml;
};

test(*grammar);


=== Pegex Grammar
--- grammar: ../pegex-pgx/pegex.pgx

=== TestML Grammar
--- grammar: ../testml-pgx/testml.pgx

=== YAML Grammar
--- grammar: ../yaml-pgx/yaml.pgx
