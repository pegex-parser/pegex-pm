##
# name:      Pegex::AST
# abstract:  Pegex Abstract Syntax Tree Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST;
use Mouse;
extends 'Pegex::Receiver';

has ast => (is => 'rw');
has stack => (is => 'rw');

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
