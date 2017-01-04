use strict; use warnings;
use Test::More;
use Pegex;

my $grammar = <<'...';
top: foo bar
foo: 'foo'
bar: /(<=oo)(bar)/
...

my $result = pegex($grammar)->parse("foobar");

is $result->{top}[0]{bar}, 'bar', 'Lookbehind works';

done_testing 1;
