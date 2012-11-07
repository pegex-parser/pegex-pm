##
# name:      Pegex::AST::Wrap
# abstract:  Pegex Wrapper AST Receiver
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2012

package Pegex::AST::Wrap;
use Pegex::Base;
extends 'Pegex::Receiver';

sub gotrule {
    my ($self, $data) = @_;
    $data // return ();
    return $data if $self->{parent}{-pass};
    return {$self->{rule} => $data}
}

1;
