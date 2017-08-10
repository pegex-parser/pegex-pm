use strict;
use warnings;

# BEGIN { $Pegex::Parser::Debug = 1 }
use Test::More tests => 8;

use Pegex;

ok defined(&pegex), 'pegex is exported';

my $parser1 = pegex("foo: <bar>\n");

is ref($parser1), 'Pegex::Parser',
    'pegex returns a Pegex::Parser object';

is $parser1->grammar->tree->{'+toprule'}, 'foo',
    'pegex() contains a grammar with a compiled tree';

my $parser2 = pegex(<<'...');
number: /<DIGIT>+/
...

eval {
    $parser2->parse('123');
    pass '$parser2->parse worked';
};

fail $@ if $@;

is ref $parser2, 'Pegex::Parser',
    'grammar property is Pegex::Parser object';

my $tree2 = $parser2->grammar->tree;
ok $tree2, 'Grammar object has tree';
ok ref($tree2), 'Grammar object is compiled to a tree';

is $tree2->{'+toprule'}, 'number', '_FIRST_RULE is set correctly';
