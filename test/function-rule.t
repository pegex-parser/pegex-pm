use strict;
use warnings;

use Test::More;
use Pegex::Parser;

{
    package G;
    use base 'Pegex::Grammar';

    sub rule_a {
        my ($self, $parser, $input) = @_;
        return;
    }

    sub rule_b {
        my ($self, $parser, $buffer, $pos) = @_;
        return $parser->match_rule(3, ['aaa', $$buffer]);
    }

    use constant text => <<'...';
top: a | b
...
}

{
    package R;
    use base 'Pegex::Tree';
    sub got_b {
        my ($self, $got) = @_;
        [reverse @$got];
    }
}

my $parser = Pegex::Parser->new(
    grammar => G->new,
    receiver => R->new,
    # debug => 1,
);

my $result = $parser->parse('xyz');

is scalar(@$result), 2, 'Got array of size 2';
is $result->[0], 'xyz', 'xyz is first';
is $result->[1], 'aaa', 'aaa is second';

done_testing;
