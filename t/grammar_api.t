use Test::More tests => 1;

package MyGrammar1;
use Pegex::Base;
extends 'Pegex::Grammar';

has text => default => sub {<<'...'};
foo: /xyz/ <bar>
bar:
    /abc/ |
    <baz>
baz: /def/
...

package main;

my $g1 = MyGrammar1->new;

is $g1->tree->{'+top'}, 'foo',
    'MyGrammar1 compiled a tree from its text';
