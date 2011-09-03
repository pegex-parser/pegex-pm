##
# name:      Pegex::AST
# abstract:  Pegex Abstract Syntax Tree Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST;
use Pegex::Receiver -base;

sub __final__ {
    my $self = shift;
    my $match = shift;
    $self->data({});
}

1;
