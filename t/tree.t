# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use t::FakeTestML;

require_or_skip('YAML::XS');

# plan tests => 12;

my @files = qw(
    t/tree.tml
    t/tree-pegex.tml
);

for my $file (@files) {
    data($file);
    loop '*grammar', \&run_tests;
}

sub run_tests {
    my ($block) = @_;
    label('$BlockLabel - Pegex::Tree');
    test($block, [ assert_equal =>
        [yaml => [parse => 'Pegex::Tree', '*grammar', '*input']],
        '*tree'
    ]);

    label('$BlockLabel - Pegex::Tree::Wrap');
    test($block, [ assert_equal =>
        [yaml => [parse => 'Pegex::Tree::Wrap', '*grammar', '*input']],
        '*wrap'
    ]);

    label('$BlockLabel - t::TestPegex::AST');
    test($block, [ assert_equal =>
        [yaml => [parse => 't::TestPegex::AST', '*grammar', '*input']],
        '*ast'
    ]);
}

done_testing;

use Pegex;
use YAML::XS;

sub parse {
    my ($receiver, $grammar, $input) = @_;
    my $parser = pegex($grammar, receiver => $receiver);
    return $parser->parse($input);
}

sub yaml {
    my ($data) = @_;
    my $yaml = YAML::XS::Dump($data);
    $yaml =~ s/^---\s+//;
    $yaml =~ s/'(\d+)':/$1:/g;
    return $yaml;
}
