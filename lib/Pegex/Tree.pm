##
# name:      Pegex::Tree
# abstract:  Pegex Parse Tree Receiver
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2012

package Pegex::Tree;
use Pegex::Base;
extends 'Pegex::Receiver';

sub gotrule {
    my $self = shift;
    @_ || return ();
    return {$self->{parser}{rule} => $_[0]}
        if $self->{parser}{parent}{-wrap};
    return $_[0];
}

1;
