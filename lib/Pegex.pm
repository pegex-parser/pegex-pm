use strict; use warnings;
package Pegex;
our $VERSION = '0.45';

use Pegex::Parser;
use Pegex::Grammar;

use Exporter 'import';
our @EXPORT = 'pegex';

sub pegex {
    my ($grammar, $receiver) = @_;
    if (not $receiver) {
        require Pegex::Tree::Wrap;
        $receiver = Pegex::Tree::Wrap->new;
    }
    $receiver = $receiver->new unless ref $receiver;
    return Pegex::Parser->new(
        grammar => Pegex::Grammar->new(text => $grammar),
        receiver => $receiver,
    );
}

1;
