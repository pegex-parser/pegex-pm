##
# name:      Pegex::Receiver
# abstract:  Pegex Receiver Base Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011, 2012

package Pegex::Receiver;
use Pegex::Base;

has parser => ();
has data => ();

# Flatten a structure of nested arrays into a single array.
sub flatten {
    my ($self, $array, $times) = @_;
    $times //= -1;
    return $array unless $times--;
    return [
        map {
            (ref($_) eq 'ARRAY') ? @{$self->flatten($_, $times)} : $_
        } @$array
    ];
}

1;
