##
# name:      Pegex::Regex
# abstract:  Use Pegex Like a Regex
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Regex;

sub import {
    require Carp;
    Carp::croak("Pegex::Regex coming soon...");
}

1;

=head1 SYNOPSIS

    {
        # Turn on Pegex regular expressions in lexical scope.
        use Pegex::Regex;
        my $grammar = qr{$grammar_text}x;
        $text =~ $grammar;
        my $data = \%/;

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

IMHO, conflating parsing with regular expression syntax is not the clearest
way to code. But, of course, TMTOWTDI. :)

=head1 TMTOWTDI

Here's a Pegex::Regex code snippet:

    use Pegex::Regex;
    $text =~ qr{path/to/grammar_file.pgx};
    print $/{foo};

And the equivalent Pegex code:

    use Pegex;
    my $data = pegex('path/to/grammar_file.pgx')->parse($text);
    print $data->{foo};

And the more explicit Pegex solution:

    use Pegex::Grammar;
    my $grammar = Pegex::Grammar->new(
        text => 'path/to/grammar_file.pgx',
    );
    my $data = $grammar->parse($input);
    print $data->{foo};

And more explicit yet:

    use Pegex::Grammar;
    use Pegex::Compiler;
    use Pegex::AST;
    my $grammar = Pegex::Grammar->new(
        tree => Pegex::Compile->compile('path/to/grammar_file.pgx')->tree,
        receiver => 'Pegex::AST',
    );
    $grammar->parse($input);
    print $grammar->receiver->data->{foo};

There are even more variations and places to use more exacting subclasses and
options. Pegex::Regex is just a gateway drug. :)

=head1 INPUT OPTIONS

There are different ways to input a grammar into a Pegex::Regex:

    qr{
        grammar: <as> <text>
    }x;
    qr{$grammar_in_a_variable}x;
    qr{path/to/grammar-file.pgx};

Make sure to use the C<x> modifier if you are specifying the grammar as a
literal string or in a variable.
