# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex::Compiler;
use Pegex::Bootstrap;
use YAML::XS;

# BEGIN { XXX \%INC}

sub pegex_compile {
    my $grammar_text = (shift)->value;
    Pegex::Compiler->new->parse($grammar_text)->tree;
}

sub bootstrap_compile {
    my $grammar_text = (shift)->value;
    Pegex::Bootstrap->new->parse($grammar_text)->tree;
}

sub compress {
    my $grammar_text = (shift)->value;
    chomp($grammar_text);
    $grammar_text =~ s/(?<!;)\n(\w+\s*:)/;$1/g;
    $grammar_text =~ s/\s//g;
    return "$grammar_text\n";
}

sub yaml {
    return YAML::XS::Dump((shift)->value);
}

__DATA__
%TestML 1.0

Plan = 60;

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


=== Single Regex
--- grammar
a: /x/

=== Single Reference
--- grammar
a: <b>

=== Single Error
--- grammar
a: `b`

=== Simple All Group
--- grammar
a: /b/ <c>

=== Simple Any Group
--- grammar
a: <b> | <c>

=== Bracketed All Group
--- grammar
a: ( <b> /c/ )

=== Bracketed Any Group
--- grammar
a: ( <b> | /c/ | `d` )

=== Bracketed Group in Unbracketed Group
--- grammar
a: <b> ( <c> | <d> )

=== Multiple Rules
--- grammar
a: <b>
b: <c>

=== Simple Grammar
--- grammar
a: ( <b> <c>* )
b: /x/
c: /y+/

=== Semicolons OK
--- grammar
a: <b>;
b: <c>
c: /d/;

=== Unbracketed
--- grammar
a: <b> <c> <d>
b: <c> | <d>

=== Not Rule
--- grammar
a: !<b> <c>

=== Multiline
--- grammar
a: <b>
   <c>
b:
    /c/ <d>
    <e>;
c:
    <d> |
    ( /e/ <f> )
    | `g`

=== Various Groups
--- grammar
a: <b> ( <c> | <d> )
b: ( <c> | <d> ) <e>
c: <d> | ( <e> <f>) | <g>
d: <e> | (<f> <g>) | <h> | ( `i` )
e: ( <f> )

=== Modifiers
--- grammar
a: !<a> =<b>
b: ( /c/ <d> )+
c: ( /c/ <d> )+

=== Any Group Plus Rule
--- grammar
a: /w/ ( <x>+ | <y>* ) <z>?

=== Equivalent
--- grammar
a: <b>
c: !<d>

=== Failing Test
--- grammar
a_b: /c/ <d>

=== Failures to test later
--- grammar
a: <b> ( <c>* | <d>+ )+
e: ( <f> !<g> )?

=== Failures to test later
--- SKIP
--- grammar
b: ( /x/ )+
