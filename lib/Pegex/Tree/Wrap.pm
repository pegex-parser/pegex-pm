package Pegex::Tree::Wrap;

use Pegex::Base;
extends 'Pegex::Receiver';

sub gotrule {
    my $self = shift;
    @_ || return ();
    return $_[0] if $self->{parser}{parent}{-flat};
    return {$self->{parser}{rule} => $_[0]}
}

sub final {
    my $self = shift;
    return(shift) if @_;
    return {$self->{parser}{rule} => []}
}

1;
