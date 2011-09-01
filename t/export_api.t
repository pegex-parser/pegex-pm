use Test::More tests => 8;

use Pegex;

ok defined(&pegex), 'pegex is exported';

my $p1 = pegex('foo: <bar>');

is ref($p1), 'Pegex::Grammar', 'pegex returns a Pegex object';

is $p1->tree->{'+top'}, 'foo',
    'pegex() contains a grammar with a compiled tree';

my $p2 = pegex(<<'...');
number: /<DIGIT>+/
...

eval {
    $p2->parse('123');
    pass '$p2->parse worked';
};

fail $@ if $@;

is ref $p2, 'Pegex::Grammar', 'grammar property is Pegex::Grammar object';

ok $p2->tree, 'Grammar object has tree';
ok ref($p2->tree), 'Grammar object is compiled to a tree';

is $p2->tree->{'+top'}, 'number', '_FIRST_RULE is set correctly';
