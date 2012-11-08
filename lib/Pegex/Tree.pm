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
    my ($self, $data) = @_;
    $data // return ();
    return {$self->{parser}{rule} => $data}
        if $self->{parser}{parent}{-wrap};
    return $data;
}

1;
