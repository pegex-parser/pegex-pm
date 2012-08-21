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
        my ($self, $data) = @_;
        $self->flatten($data, 2);
    }
    sub got_b {
        my ($self, $data) = @_;
        [$data];
    }
    sub got_c {
        my ($self, $data) = @_;
        [$data];
    }
}

my $parser = pegex($grammar, {receiver => 'R'});
my $data = $parser->parse('xxx');

is join('', @$data), 'xxx', 'Array was flattened';
