# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Compile::Debug = 1 }

use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;
use YAML::XS;

sub pegex_compile {
    my $grammar_text = (shift)->value;
    Pegex::Compiler->new->parse($grammar_text)->tree;
}

sub bootstrap_compile {
    my $grammar_text = (shift)->value;
    Pegex::Compiler::Bootstrap->new->parse($grammar_text)->tree;
}

sub compress {
    my $grammar_text = (shift)->value;
    chomp($grammar_text);
    $grammar_text =~ s/(?<!;)\n(\w+\s*:)/;$1/g;
    $grammar_text =~ s/\s//g;
    return $grammar_text;
}

sub yaml {
    return YAML::XS::Dump((shift)->value);
}

__DATA__
%TestML 1.0

# Plan = 15;
Plan = 12;

test = (grammar) { 
    Label = '$BlockLabel - Does the compiler output match the bootstrap?';
    grammar.pegex_compile.yaml
      == grammar.bootstrap_compile.yaml;

    Label = '$BlockLabel - Does the compressed grammar compile the same?';
    grammar.compress.pegex_compile.yaml
      == grammar.compress.bootstrap_compile.yaml;

    Label =
        '$BlockLabel - Does the compressed grammar match the uncompressed?';
    grammar.compress.pegex_compile.yaml
      == grammar.pegex_compile.yaml;
};

test(*grammar);


=== Simple Grammar
--- grammar
a: [ <b> <c>* ]
b: /x/
c: /y+/

=== Semicolons OK
--- grammar
a: /x/;
b: /y/;

=== Unbracketed
--- grammar
a: <b> <c> <d>
b: <c> | <d>

=== Not Rule
--- grammar
a: !<b> <c>

=== Any Group Plus Rule
--- SKIP
--- grammar
a: [ <b> | <c> ] <d>

=== Equivalent
--- SKIP
--- grammar
a: <b>
c: !<d>

=== Failing Test
--- SKIP
--- grammar
a_b: /c/ <d>


=== Failures to test later
--- SKIP
--- grammar
a: <b> [ <c>* | <d>+ ]?
e: [ <f> ]
