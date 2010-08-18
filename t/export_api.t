use Test::More tests => 8;

use Pegex;

ok defined(&pegex), 'pegex is exported';

my $p1 = pegex('foo');

is ref($p1), 'Pegex', 'pegex returns a Pegex object';

is $p1->grammar->grammar_text, 'foo', 'pegex() sets grammar_text property';

my $p2 = pegex(<<'...');
number: /<DIGIT>+/
...


eval {
    $p2->parse('123');
    pass '$p2->parse worked';
};

fail $@ if $@;

is ref $p2->grammar, 'Pegex::Grammar', 'grammar property is Pegex::Grammar object';

ok $p2->grammar->grammar_text, 'Grammar object has grammar_text';
ok $p2->grammar->grammar, 'Grammar object is compiled to a tree';

is $p2->grammar->grammar->{_FIRST_RULE}, 'number', '_FIRST_RULE is set correctly';
