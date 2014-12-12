Plan to fast-track the Pegex BootStrap with CafeScript
======================================================

Pegex wants to be the way to make writing new markups, languages, and
cross-language DSLs, be childsplay, and accessible to all programmers of all
modern languages.

Pegex has a goal to have 100 grammars that are composable, extensible and
mashable, so that anyone can easily create new things or patch old ones, and
have have the patches serve all languages at once.

Pegex has a goal to be ported to 20+ programming languages, such that new DSLs
written in it, work everywhere automatically.

Pegex implmentations pass the same TestML suite, so that they all work the
same. Pegex has been fully implemented in Perl and fully ported to Ruby (and
partially to JavaScript and Python). The process is arduous.

Recently a plan has emerged to make the porting/bootstrapping of Pegex much
easier. This document details that plan.

== Step 1

Convert CoffeeScript grammar.pegjs to CafeScript.pgx (Pegex grammar) and
CafeScript::AST (Perl receiver module). This plus Pegex.pm framework will be
the first half of the CafeScript compiler.

Note that only enough of CoffeeScript to write the Pegex and TestML frameworks
in, needs to be converted.

See:

* https://github.com/michaelficarra/CoffeeScriptRedux/blob/master/src/grammar.pegjs
* https://github.com/ingydotnet/pegex-pm
* https://github.com/ingydotnet/testml-pm

== Step 2

Write an AST analyzer to assign (mostly implicit) type info to the AST. The AST
needs to be typeful, to generate proper code in various languages.

== Step 3

Write the AST to Perl backend. Now we have a Cafe→Perl compiler.

== Step 4

Rewrite Pegex and TestML in CafeScript, such that they generate equivalent
(test passing) code to the original hand written ones.

== Step 5

Write Ruby, Python and JavaScript backends. Now Pegex works in all these languages.

== Step 6

Rewrite current Pegex compiler receivers (JSON, JSONY, etc) in CafeScript. Now
these compilers are write-once-use-everywhere.

== Step 7

Write a Pegex/Cafe/TEstML based YAML loader. Now YAML works exactly the same
across languages. Bugs get fixed once, for all. Acmeism works.

== Challenges

All this is pretty staightforward, except Step 2 involves some language design.
CageScript must accomodate typeful code. Luckily, this can all be test driven,
since the (initial) purpose of CafeScript is only to serve Pegex (very limited
and known domain).
