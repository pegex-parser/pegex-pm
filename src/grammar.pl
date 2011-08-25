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
# name:      Pegex::Compiler::Grammar
# abstract:  Pegex Grammar for a Pegex Grammar
# author:    Ingy döt Net <ingy\@cpan.org>
# license:   perl
# copyright: 2010, 2011

# XXX Should be renamed to Pegex::Grammar::Pegex
package Pegex::Compiler::Grammar;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub tree {
    return +$perl;
}

1;
...
