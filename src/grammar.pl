use lib "$ENV{HOME}/src/pegex-pm/lib";
use Pegex::Compiler::Bootstrap;

open IN, shift or die;
my $grammar = do {local $/; <IN>};
my $compiler = Pegex::Compiler::Bootstrap->new;
$compiler->compile($grammar);
my $perl = $compiler->to_perl;
chomp($perl);

print <<"...";
##
# name:      Pegex::Grammar::Pegex
# abstract:  Pegex Grammar for the Pegex Grammar Language
# author:    Ingy döt Net <ingy\@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Grammar::Pegex;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub build_tree {
    return +$perl;
}

1;
...
