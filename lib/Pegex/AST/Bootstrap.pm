##
# name:      Pegex::AST::Bootstrap
# abstract:  Pegex Abstract Syntax Tree Bootstrap for TestML
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST::Bootstrap;
use Pegex::Receiver -base;

sub __final__ {
    my $self = shift;
    my $match = shift;
    $self->data({});
}

1;
