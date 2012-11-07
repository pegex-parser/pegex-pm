##
# name:      Pegex
# abstract:  Acmeist PEG Parsing Framework
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011, 2012
# see:
# - Pegex::API
# - Pegex::Syntax
# - Pegex::Tutorial
# - http://github.com/ingydotnet/pegex-pm
# - irc.freenode.net#pegex

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
    my ($receiver) = _get_options(@_);
    return Pegex::Parser->new(
        grammar => Pegex::Grammar->new(text => $grammar_text),
        receiver => $receiver,
    );
}

sub _get_options {
    my $options = (@_ > 1) ? {@_} : (shift || {});
    my $receiver;
    if ($receiver = $options->{receiver}) {
        if (not ref $receiver) {
            eval "require $receiver";
            die $@ if $@ and $@ !~ /Can't locate/;
            $receiver = $receiver->new;
        }
    }
    else {
        require Pegex::Tree::Wrap;
        $receiver = Pegex::Tree::Wrap->new;
    }
    return ($receiver);
}

1;

=head1 Synopsis

    use Pegex;
    my $result = pegex($grammar)->parse($input);

or with options:

    use Pegex;
    use ReceiverClass;
    my $parser = pegex($grammar, receiver => 'ReceiverClass');
    my $result = $parser->parse($input);

or more explicitly:

    use Pegex::Parser;
    use Pegex::Grammar;
    my $pegex_grammar = Pegex::Grammar->new(
        text => $grammar,
    );
    my $parser = Pegex::Parser->new(
        grammar => $pegex_grammar,
    );
    my $result = $parser->parse($input);

or customized explicitly:

    {
        package MyGrammar;
        use Pegex::Base;
        extends 'Pegex::Grammar';
        has text => "your grammar definition text goes here";
        has receiver => "MyReceiver";
    }
    {
        package MyReceiver;
        use base 'Pegex::Receiver';
        got_some_rule { ... }
        got_other_rule { ... }
    }
    use Pegex::Parser;
    my $parser = Pegex::Parser->new(
        grammar => MyGrammar->new,
        receiver => MyReceiver->new,
    );
    $parser->parse($input);
    my $result = $parser->receiver->data;

=head1 Description

Pegex is a Acmeist parser framework. It allows you to easily create parsers
that will work equivalently in lots of programming languages!

Pegex gets it name by combining Parsing Expression Grammars (PEG), with
Regular Expessions (Regex). That's actually what Pegex does.

PEG is the cool new way to elegantly specify recursive descent grammars. The
Perl 6 language is defined in terms of a self modifying PEG language called
B<Perl 6 Rules>. Regexes are familiar to programmers of most modern
programming languages. Pegex defines a simple PEG syntax, where all the
terminals are regexes. This means that Pegex can be quite fast and powerful.

Pegex attempts to be the simplest way to define new (or old) Domain Specific
Languages (DSLs) that need to be used in several programming languages and
environments.

=head1 Usage

The C<Pegex.pm> module itself is just a trivial way to use the Pegex
framework. It is only intended for the simplest of uses.

This module exports a single function, C<pegex>, which takes a Pegex grammar
string as input. You may also pass named parameters after the grammar.

    my $parser = pegex($grammar, receiver => 'MyReceiver');

The C<pegex> function returns a L<Pegex::Parser> object, on which you would
typically call the C<parse()> method, which (on success) will return a data
structure of the parsed data.

See L<Pegex::API> for more details.
