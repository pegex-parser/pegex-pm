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

sub final {
    my $self = shift;
    return(shift) if @_;
    return [];
}

1;

=head1 SYNOPSIS

    use Pegex;
    $tree = pegex($grammar, receiver => 'Pegex::Tree')->parse($input);

=head1 DESCRIPTION

L<Pegex::Tree> is receiver class that will shape the captured data from a Pegex
parse operation into a tree made out of arrays.

This module is a very (probably the most) common base class for writing your
own receiver class.
