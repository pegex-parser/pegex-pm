BEGIN { $Pegex::Bootstrap = 1 }
use lib "$ENV{HOME}/src/pegex-pm/lib";
use Pegex::Compiler;

my $perl = Pegex::Compiler->compile(shift)->to_perl;
chomp($perl);

$perl =~ s/^/  /gm;

print <<"...";
##
# name:      Pegex::Grammar::Pegex
# abstract:  Pegex Grammar for the Pegex Grammar Language
# author:    Ingy döt Net <ingy\@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Pegex::Grammar;
use Pegex::Mo;
extends 'Pegex::Grammar';

sub tree_ {
$perl
}

1;
...
