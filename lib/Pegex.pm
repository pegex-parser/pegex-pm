use v5.10.0; use strict; use warnings;

package Pegex;

use Pegex::Parser;
use Pegex::Grammar;

# VERSION
# ABSTRACT: Acmeist PEG Parsing Framework 

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
