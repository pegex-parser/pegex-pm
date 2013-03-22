use v5.10.0;
use strict;
use warnings;

package Pegex;

use Pegex::Parser;
use Pegex::Grammar;

our $VERSION = '0.21';

use Exporter 'import';
our @EXPORT = 'pegex';

# pegex() is a sugar method that takes a Pegex grammar string and returns a
# Pegex::Parser object.
sub pegex {
    my $grammar_text = shift;
    die "pegex() requires at least 1 argument, a pegex grammar string"
        unless $grammar_text;
    return Pegex::Parser->new(
        grammar => Pegex::Grammar->new(text => $grammar_text),
        _get_options(@_),
    );
}

sub _get_options {
    my $options = (@_ > 1) ? {@_} : (shift || {});
    my $receiver;
    if ($receiver = $options->{receiver}) {
        if (not ref $receiver) {
            eval "require $receiver";
            die $@ if $@ and $@ !~ /Can't locate/;
            $options->{receiver} = $receiver->new;
        }
    }
    else {
        require Pegex::Tree::Wrap;
        $options->{receiver} = Pegex::Tree::Wrap->new;
    }
    return %$options;
}

1;
