use strict;
use t::FakeTestML;

require_or_skip('YAML::XS');

plan tests => 63;

data 't/compiler.tml';
loop '*grammar', \&run_tests;

sub run_tests {
    my ($block) = @_;
    label '$BlockLabel - Compiler output matches bootstrap?';
    test(
        $block,
        [ assert_equal =>
            [yaml => [pegex_compile => '*grammar']],
            [yaml => [bootstrap_compile => '*grammar']],
        ],
    );

    label '$BlockLabel - Compressed grammar compiles the same?';
    test(
        $block,
        [ assert_equal =>
            [yaml => [pegex_compile => [compress => '*grammar']]],
            [yaml => [bootstrap_compile => [compress => '*grammar']]],
        ],
    );

    label '$BlockLabel - Compressed grammar matches uncompressed?';
    test(
        $block,
        [ assert_equal =>
            [yaml => [pegex_compile => [compress => '*grammar']]],
            [yaml => [pegex_compile => '*grammar']],
        ],
    );
}

done_testing;

use Pegex::Compiler;
use Pegex::Bootstrap;
use YAML::XS;

# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

sub pegex_compile {
    my $grammar_text = shift;
    Pegex::Compiler->new->parse($grammar_text)->tree;
}

sub bootstrap_compile {
    my $grammar_text = shift;
    Pegex::Bootstrap->new->parse($grammar_text)->tree;
}

sub compress {
    my $grammar_text = shift;
    chomp($grammar_text);
    $grammar_text =~ s/(?<!;)\n(\w+\s*:)/;$1/g;
    $grammar_text =~ s/\s//g;

    # XXX mod/quant ERROR rules are too prtective here:
    $grammar_text =~ s/>%</> % </g;

    return "$grammar_text\n";
}

sub yaml {
    return YAML::XS::Dump(shift);
}
