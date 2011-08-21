use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;
use YAML::XS;

sub pegex_compile {
    my $grammar = (shift)->value;
    my $compiler = Pegex::Compiler->new(debug => 0);
    return $compiler->compile($grammar)->grammar;
}

sub bootstrap_compile {
    my $grammar = (shift)->value;
    my $compiler = Pegex::Compiler::Bootstrap->new;
    return $compiler->compile($grammar)->grammar;
}

sub compress {
    my $grammar = (shift)->value;
    chomp($grammar);
    $grammar =~ s/(?<!;)\n(\w+\s*:)/;$1/g;
    $grammar =~ s/\s//g;
    return $grammar;
}

sub yaml {
    return YAML::XS::Dump((shift)->value);
}

__DATA__
%TestML 1.0

Plan = 15;

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
a: <!b> <c>

=== Equivalent
--- grammar
a: <b>
c: <!d>


=== Failures to test later
--- SKIP
--- grammar
a: <b> [ <c>* | <d>+ ]?
e: [ <f> ]
