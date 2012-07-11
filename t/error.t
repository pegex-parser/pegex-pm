# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use TestML -run;

use Pegex;

sub parse {
    my $grammar = (shift)->value;
    my $input = (shift)->value;
    my $pegex = pegex($grammar);
    $pegex->tree;
    return $pegex->parse($input);
}


__DATA__
%TestML 1.0

Plan = 1;

*grammar.parse(*input).Catch ~~ *error;

=== Error fails at furthest match
--- grammar
a: b+ c
b: /b/
c: /c/
--- input
bbbbddddd
--- error: "ddddd\n"
