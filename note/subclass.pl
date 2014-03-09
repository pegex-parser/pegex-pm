use strict;
use lib 'lib';

{
    package P;
    use base 'Pegex::Parser';

    use XXX;
    sub match_ref {
        my ($self, $ref, $parent) = @_;
        my $stack = $self->{stack} ||= [];
        push @$stack, $ref;
        my $rc = $self->SUPER::match_ref($ref, $parent);
        pop @$stack;
        return $rc;
    }
}

{
    package R;
    use base 'Pegex::Tree';
    use XXX;

    sub got_b {
        XXX $_[0]->{parser}{stack};
    }
}

{
    package G;
    use base 'Pegex::Grammar';
    use constant text => <<'...';
a: b+
b: /(xyz)/
...
}

P->new(
    grammar => G->new,
    receiver => R->new,
)->parse('xyzxyzxyz');
