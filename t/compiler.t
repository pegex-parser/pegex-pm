use Test::More tests => 1;

use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;
use YAML::XS;

compare(<<'...');
a: [ <b> <c>* ]
b: /x/
c: /y+/
...

# compare("a:[<b><c>*];b:/x/;c:/y+/");

sub compare {
    my $grammar = shift;
    my $expected = YAML::XS::Dump(Pegex::Compiler::Bootstrap->new->compile($grammar)->grammar);
    my $got = YAML::XS::Dump(Pegex::Compiler->new->compile($grammar)->grammar);

    is $got, $expected;
}
