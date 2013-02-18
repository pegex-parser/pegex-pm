use t::FakeTestML;

require_or_skip('YAML::XS');

data 't/compiler-checks.tml';

# *grammar.bootstrap_compile.yaml.clean == *yaml;
loop([ assert_equal =>
    [clean => [yaml => [bootstrap_compile => '*grammar']]],
    '*yaml',
]);

done_testing;

# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use Pegex::Bootstrap;
use YAML::XS;

sub bootstrap_compile {
    my $grammar_text = shift;
    my $compiler = Pegex::Bootstrap->new;
    my $tree = $compiler->parse($grammar_text)->combinate->tree;
    delete $tree->{'+toprule'};
    return $tree;
}

sub yaml {
    return YAML::XS::Dump(shift);
}

sub clean {
    my $yaml = shift;
    $yaml =~ s/^---\s//;
    $yaml =~ s/'(\d+)'/$1/g;
    return $yaml;
}
