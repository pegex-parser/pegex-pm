use lib "$ENV{HOME}/src/pegex-pm/lib";
use Pegex::Compiler::Bootstrap;

open IN, shift or die;
my $grammar = do {local $/; <IN>};
my $perl = Pegex::Compiler::Bootstrap->compile($grammar)->combinate->to_perl;
chomp($perl);

print <<"...";
package Pegex::Compiler::Grammar;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub grammar_tree {
    return +$perl;
}

1;
...
