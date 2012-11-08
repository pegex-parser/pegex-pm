##
# name:      Pegex::Regex
# abstract:  Use Pegex Like a Regex
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011, 2012
# see:
# - Pegex
# - Regexp::Grammars

package Pegex::Regex;

use Pegex::Parser;
use Pegex::Grammar;
use Pegex::Receiver;

my @parsers;
my $PASS = '';
my $FAIL = '(*FAIL)';

sub generate_regex {
    push @parsers, Pegex::Parser->new(
        grammar => Pegex::Grammar->new( text => shift ),
        receiver => Pegex::Receiver->new,
        throw_on_error => 0,
    );
    my $index = $#parsers;
    my $regex = "(??{Pegex::Regex::parse($index, \$_)})";
    use re 'eval';
    return qr{$regex};
}

sub parse {
    my ($index, $input) = @_;
    undef %/;
    my $ast = $parsers[$index]->parse($input) or return $FAIL;
    %/ = %$ast if ref($ast) eq 'HASH';
    return $PASS;
};

# The following code was mutated from Damian Conway's Regexp::Grammars
sub import {
    # Signal lexical scoping (active, unless something was exported)...
    $^H{'Pegex::Regex::active'} = 1;

    # Process any regexes in module's active lexical scope...
    use overload;
    overload::constant(
        qr => sub {
            my ($raw, $cooked, $type) = @_;
            # If active scope and really a regex...
            return generate_regex($raw)
                if _module_is_active() and $type =~ /qq?/;
            # Ignore everything else...
            return $cooked;
        }
    );
}

# Deactivate module's regex effect when it is "anti-imported" with 'no'...
sub unimport {
    # Signal lexical (non-)scoping...
    $^H{'Pegex::Regex::active'} = 0;
}

# Encapsulate the hoopy user-defined pragma interface...
sub _module_is_active {
    return (caller 1)[10]->{'Pegex::Regex::active'};
}

1;

=head1 NOTE

This module is just for experimental fun. See L<Pegex> for the right way to use
the Pegex parsing framework.

=head1 SYNOPSIS

    {
        # Turn on Pegex regular expressions in lexical scope.
        use Pegex::Regex;
        my $grammar = qr{$grammar_text}x;
        $text =~ $grammar;
        my $result = \%/;

        # Turn off Pegex in this scope.
        no Pegex::Regex;
    }

=head1 DESCRIPTION

This is a trivial sugar module that lets you use Pegex parser grammars like
regular expressions, if you're into that kind of thing.

This is basically a clone of Damian Conway's L<Regexp::Grammars> module API.
You put a grammar into a C<qr{...}x> and apply it the input string you want to
parse. If the parse is successful, you get a data structure of the content in
C<%/>.

IMHO, building a recursive decscent parser entirely inside of a regular
expression, is not the clearest way to code. But, of course, TMTOWTDI. :)

=head1 TMTOWTDI

Here's a Pegex::Regex code snippet:

    use Pegex::Regex;
    $text =~ qr{... Pegex grammar text ...};
    $data = \%/;

And the equivalent Pegex code:

    use Pegex;
    my $data = pegex('... Pegex grammar text ...')->parse($text);

=head1 WARNING

This gateway drug, er, module, technically should not even work.

It turns your "grammar inside a regexp" into a Pegex::Grammar using qr{}
overloading, and then turns your regexp itself into a shim that calls the
parse method for you. This is highly magical and technically makes a reentrant
call to the regex engine, which is not supported yet.  Use at your own risk.

Better yet, do yourself a favor and learn how to use the Pegex toolset without
this ::Regex sugar.  C<:-)>
