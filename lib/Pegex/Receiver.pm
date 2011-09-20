##
# name:      Pegex::Receiver
# abstract:  Pegex Receiver Base Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Receiver;
use Pegex::Mo;

has 'parser';
has 'data';
has wrap => default => sub { 0 };

1;
