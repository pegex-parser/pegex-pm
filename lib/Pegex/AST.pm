##
# name:      Pegex::AST
# abstract:  Pegex Generic AST Receiver
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2012

package Pegex::AST;
use Pegex::Base;
extends 'Pegex::Receiver';

sub gotrule {
    my ($self, $data, $name, $parent) = @_;
    $data // ();
}

1;
