use t::FakeTestML;

require_or_skip('YAML::XS');

data do { local $/; <DATA> };

loop([ assert_equal =>
    [yaml => [compile => '*grammar1']],
    [yaml => [ compile => '*grammar2' ]]
]);

done_testing;

# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use Pegex::Compiler;
use YAML::XS;

sub compile {
    my $grammar_text = shift;
    Pegex::Compiler->new->parse($grammar_text)->tree;
}

sub yaml {
    return YAML::XS::Dump(shift);
}

__DATA__
=== Simple Test Case
--- grammar1
a: /x/
--- grammar2
a:
    /x/

=== And over Or Precedence
--- grammar1
a: b c | d
--- grammar2
a: ( b c ) | d

=== And/Or Precedence with joining
--- grammar1
a: b % c | d %% e
--- grammar2
a: ( b % c ) | ( d %% e )

=== And/Or Precedence with grouping
--- grammar1
a:
     b c
   | (
        d
      | e
      | f g h i
   )
--- grammar2
a: ( b c ) | ( d | e | ( f g h i ) )

=== In-Line Comments
--- grammar1
a:  # test
    b c  # not d
    /q/  # skipping to q
    % e  # using e here...
    ;    # comment -> semicolon test
--- grammar2
a: b c /q/ % e

=== Token Per Line
--- SKIP: TODO
--- grammar1
a: /b/
--- grammar2
a
:
/b/

=== Regex Combination
--- SKIP: TODO
--- grammar1: a: /b/ /c/
--- grammar2: a: /bc/

=== Regex Combination by Reference
--- SKIP: TODO
--- grammar1
a: b /c/
b: /b/
--- grammar2: a: /bc/

=== Multiple Rules Names per Definition
--- SKIP: TODO
--- grammar1
a b: /O HAI/
--- grammar2
a: /O HAI/
b: /O HAI/
