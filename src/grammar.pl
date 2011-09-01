use lib "$ENV{HOME}/src/pegex-pm/lib";
use Pegex::Compiler;

my $perl = Pegex::Compiler->compile(shift)->to_perl;
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

sub tree_ {
    return +$perl;
}

1;
...
