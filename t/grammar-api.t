use Test::More tests => 1;

package MyGrammar1;
use Mouse;
extends 'Pegex::Grammar';

use constant text => <<'...';
foo: /xyz/ <bar>
bar:
    /abc/ |
    <baz>
baz: /def/
...

package main;

my $g1 = MyGrammar1->new;

is $g1->tree->{'+toprule'}, 'foo',
    'MyGrammar1 compiled a tree from its text';
