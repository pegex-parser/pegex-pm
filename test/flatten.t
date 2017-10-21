use strict;
use warnings;

use Test::More tests => 1;
use Pegex;

my $grammar = <<'...';
a: (((b)))+
b: (c | d)
c: /(x)/
d: /y/
...

{
    package R;
    use base 'Pegex::Receiver';
    sub got_a {
        my ($self, $got) = @_;
        $self->flatten($got);
        $got;
    }
    sub got_b {
        my ($self, $got) = @_;
        [$got];
    }
    sub got_c {
        my ($self, $got) = @_;
        [$got];
    }
}

my $parser = pegex($grammar, 'R');
my $got = $parser->parse('xxx');

is join('', @$got), 'xxx', 'Array was flattened';
