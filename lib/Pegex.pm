use strict; use warnings;
package Pegex;
our $VERSION = '0.51';

use Pegex::Parser;

use Exporter 'import';
our @EXPORT = 'pegex';

sub pegex {
    my ($grammar, $receiver) = @_;
    die "Argument 'grammar' required in function 'pegex'"
        unless $grammar;
    if (not ref $grammar or $grammar->isa('Pegex::Input')) {
        require Pegex::Grammar;
        $grammar = Pegex::Grammar->new(text => $grammar),
    }
    if (not defined $receiver) {
        require Pegex::Tree::Wrap;
        $receiver = Pegex::Tree::Wrap->new;
    }
    elsif (not ref $receiver) {
        eval "require $receiver; 1";
        $receiver = $receiver->new;
    }
    return Pegex::Parser->new(
        grammar => $grammar,
        receiver => $receiver,
    );
}

1;
