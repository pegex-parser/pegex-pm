use strict; use warnings;
use Pegex;
use XXX;

my $g1 = <<'...';
t1: a b? c* d+

a: /(a)/
b: /(b)/
c: /(c)/
d: /(d)/

...

my $i1 = 'abcd';

YYY pegex($g1)->grammar->tree;
YYY pegex($g1, 'Pegex::Tree')->parse($i1, 't1');


__END__
/abc/               T
/(a)/               *
xxx /(a)(b)(c)/ yyy         [*]


re1: /(a)(b)(c)/
a                   *
a?                  ? | *
a*                  [*]
a+                  [*]
a<x,y>              []
(a b)*              [[0,0]]
( a | b | c )       *
( a b c )           [***]


x: foo*


a<n,m> % b   a (b a)<n-1,m-1>
a<n,m> %% b   a (b a)<n-1,m-1> b?
