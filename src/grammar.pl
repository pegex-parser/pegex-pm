use lib "$ENV{HOME}/src/pegex-pm/lib";
use Pegex::Compiler::Bootstrap;

open IN, shift or die;
my $grammar = do {local $/; <IN>};
my $perl = Pegex::Compiler::Bootstrap->compile($grammar)->combinate->to_perl;
chomp($perl);

print <<"...";
##
# name:      Pegex::Compiler::Grammar
# abstract:  Pegex Grammar for a Pegex Grammar
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler::Grammar;
use Mouse;
extends 'Pegex::Grammar';

sub grammar_tree {
    return +$perl;
}

1;
...
