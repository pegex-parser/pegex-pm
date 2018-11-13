#!/usr/bin/env testml-pl5

# XXX Bug in testml perl5 runtime for exec_func
# % *pgx.compile.(compiled)=>
#   compiled.ok == True :"+: '{*pgx}' compiled"
#   compiled.perl !=~ *not :"+: No '{*not}'"

*pgx.compile-pegex.ok == True :"+: '{*pgx}' compiled"
*pgx.compile-pegex.perl !=~ *not :"+: No '{*not}'"


=== Test 1
--- pgx
all: /\x{FEFF}/
--- not(/): /u$

=== Test 2
--- pgx
all: 'xxx' /\x{FEFF}/ 'yyy'
--- ^not

