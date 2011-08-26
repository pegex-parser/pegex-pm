##
# name:      Pegex::AST
# abstract:  Pegex Abstract Syntax Tree Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST;
use Pegex::Receiver -base;

sub __begin__ {
    my $self = shift;
    $self->data({});
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
#     WWW { rule => $rule, kind => $kind };
}

sub __not__ {
    my $self = shift;
    my $rule = shift;
    my $kind = shift;
}

sub __end__ {
    my $self = shift;
}

1;
