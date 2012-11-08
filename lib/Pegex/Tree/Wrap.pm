##
# name:      Pegex::Tree::Wrap
# abstract:  Pegex Wrapper Parse Tree Receiver
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2012
# see:
# - Pegex::Receiver
# - Pegex::Tree

package Pegex::Tree::Wrap;
use Pegex::Base;
extends 'Pegex::Receiver';

sub gotrule {
    my ($self, $data) = @_;
    $data // return ();
    return $data if $self->{parser}{parent}{-pass};
    return {$self->{parser}{rule} => $data}
}

1;
