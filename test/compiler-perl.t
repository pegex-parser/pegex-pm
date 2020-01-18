#!/usr/bin/env testml-pl5

# XXX Bug in testml perl5 runtime for exec_func
# % *pgx.compile.(compiled)=>
#   compiled.ok == True :"+: '{*pgx}' compiled"
#   compiled.perl !=~ *not :"+: No '{*not}'"

*pgx.compile.ok == True :"+: '{*pgx}' compiled"
*pgx.compile.perl !=~ *not :"+: No '{*not}'"


%Bridge perl5

use lib 'lib';  # Avoid using testml/ext/perl5/Pegex*
use Pegex::Compiler;
use TestML::Boolean;

sub compile {
    my ($self, $pgx) = @_;
    my $unit = Pegex::Compiler->new->compile($pgx);
    return $unit;
}

sub ok {
    my ($self, $compiled) = @_;
    return $compiled->tree ? true : false;
}

sub perl {
    my ($self, $compiled) = @_;
    return $compiled->to_perl;
}


=== Test 1
--- pgx
all: /\x{FEFF}/
--- not(/): /u$

=== Test 2
--- pgx
all: 'xxx' /\x{FEFF}/ 'yyy'
--- ^not

