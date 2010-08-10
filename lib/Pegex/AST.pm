package Pegex::AST;
use Pegex::Receiver -base;

has 'ast';
has 'stack';

# use XXX;

sub __begin__ {
    my $self = shift;
    my $ast = $self->ast({});
    my $stack = $self->stack([]);
}

sub __try__ {
    my $self = shift;
    my $rule = shift;
    my $kind = shift;
}

sub __got__ {
    my $self = shift;
    my $rule = shift;
    my $kind = shift;
}

sub __not__ {
    my $self = shift;
    my $rule = shift;
    my $kind = shift;
}

sub __end__ {
    my $self = shift;
    $self->data($self->ast);
}

1;
