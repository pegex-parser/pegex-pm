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
    my $self = shift;
    @_ || return ();
    return $_[0] if $self->{parser}{parent}{-pass};
    return {$self->{parser}{rule} => $_[0]}
}

sub final {
    my $self = shift;
    return(shift) if @_;
    return {$self->{parser}{rule} => []}
}

1;

=head1 SYNOPSIS

    use Pegex;
    $tree = pegex($grammar, receiver => 'Pegex::Tree::Wrap')->parse($input);

=head1 DESCRIPTION

L<Pegex::Tree> is receiver class that will shape the captured data from a Pegex
parse operation into a tree made out of hashes. The keys of the hashes are the
rule names that matched, and the values are arrays of captured data.

This module is not often used as a receiver base class, but it is the default
receiver for a Pegex parse. That's because the tree is very readble with all
the rule keys in it.
