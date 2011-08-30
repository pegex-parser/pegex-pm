##
# name:      Pegex
# abstract:  Pegex Parser Generator
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011
# see:
# - Pegex::Regex
# - Pegex::Grammar
# - http://github.com/ingydotnet/pegex-pm
# - irc.freenode.net#pegex

use 5.010;
package Pegex;
use Pegex::Base -base;
use Pegex::Grammar;
use Pegex::Compiler;

our $VERSION = '0.14';

our @EXPORT = qw(pegex);

has 'grammar';

sub pegex {
    die 'Pegex::pegex takes one argument ($grammar_text)'
        unless @_ == 1;
    return 'Pegex'->new(
        grammar => Pegex::Grammar->new(
            tree => Pegex::Compiler->compile($_[0])->tree,
        ),
    );
}

sub parse {
    my $self = shift;
    die 'Pegex->parse() takes one or two arguments ($input, $start_rule)'
        unless @_ >= 1 and @_ <= 2;
    return $self->grammar->parse(@_);
}

1;

=head1 SYNOPSIS

    use Pegex;
    my $data = pegex($grammar_text)->parse($input_text);

or with regular expression sugar:

    use Pegex::Regex;
    $input_text =~ qr{<pegex> $grammar_text}x;
    my $data = \%/;

or more explicitly:

    use Pegex::Grammar;
    use Pegex::Compiler;
    use Pegex::AST;
    my $grammar = Pegex::Grammar->new(
        grammar => Pegex::Compiler->compile($grammar_text),
        receiver => Pegex::AST->new(),
    );
    my $data = $grammar->parse($input_text, 'rule_name');

or customized explicitly:       XXX - review this after refactor

    package MyGrammar;
    use Pegex::Grammar -base;

    has text => "your grammar definition text goes here";
    has receiver => "MyReceiver";

    package MyReceiver;
    use Pegex::Receiver -base;
    got_some_rule { ... }
    got_other_rule { ... }

    package main;
    use MyGrammar;
    my $grammar = MyGrammar->new();
    $grammar->parse($input);
    my $data = $receiver->data;

=head1 DESCRIPTION

Pegex is a Acmeist parser framework. It allows you to easily create parsers
that will work equivalently in lots of programming langugages!

Pegex gets it name by combining Parsing Expression Grammars (PEG), with
Regular Expessions (regex). That's actually what Pegex does.

PEG is the cool new way to elegantly specify recursive descent grammars. The
Perl 6 language is defined in terms of a self modifying PEG language called
B<Perl 6 Rules>. Regular expressions are familar to programmers of most modern
programming languages. Pegex defines a simple PEG syntax, where all the
terminals are regular expressions. This means that Pegex can be quite fast and
powerful.

Pegex attempts to be the simplest way to define new (or old) Domain Specific
Languages (DSLs) that need to be used in several programming languages and
environments.

=head1 OVERVIEW

In the diagram below, there is a simple language called Foo. The diagram shows
how Pegex can take a text grammar defining Foo and generate a parser that can
parse Foo sources into data (abstract syntax trees).

                            Parsing a language called "Foo"
                               with the Pegex toolset.    

                              .-----------------------.
  .--------------------.      |    Pegex::Compiler    |
  |    Foo Language    |      |-----------------------|    Serialize
  |--------------------|----->| Pegex::Grammar::Pegex |---------.
  | Pegex grammar text |      | Pegex::AST receiver   |         |
  '--------------------'      '-----------------------'         v
  ......................                  |                 .------.
  |                    |                  | compile()       | YAML |
  |foo:: <verb> <noun> |                  v                 '------'
  |verb: /Hello/       |       .--------------------.       .------.
  |noun: /world/       |       | Foo grammar tree   |       | JSON |
  |                    |       '--------------------'       '------'
  ......................                  |                 .------.
                                          |                 | Perl |
                                          v                 '------'
                               .---------------------.      .--------.
                               | Pegex::Grammar::Foo |      | Python |
                               |---------------------|      '--------'
                               | Pegex::Parser       |      .-----.
                               | Pegex::AST::Foo     |      | etc |
   .-----------------.         '---------------------'      '-----'
   |  Foo Language   |                    |
   |-----------------|------------------->| parse()
   | Foo source text |                    v
   '-----------------'        .----------------------.
   ...................        | Parsed Foo Data Tree |
   |Hello world      |        '----------------------'
   ...................        ........................
                              |- verb: Hello         |
                              |- noun: world         |
                              ........................

=head1 FYI

Pegex is self-hosting. This means that the Pegex grammar language syntax is
defined by a Pegex grammar! This is important because (just like any Pegex
based language) it makes it easier to port to new programming languages. You
can find the Pegex grammar for Pegex grammars here:
L<http://github.com/ingydotnet/pegex-pgx/>.

Pegex was originally inspired by Perl 6 Rules. It also takes ideas from Damian
Conway's Perl 5 module, Regex::Grammars. Pegex tries to take the best ideas
from these great works, and make them work in as many languages as possible.
That's Acmeism.

=head1 A REAL WORLD EXAMPLE

L<TestML> is a new Acmeist unit test language. It is perfect for software that
needs to run equivalently in more than one language. 

TestML has a language specification grammar:
http://www.testml.org/specification/language/

The Perl6 implementation of TestML uses this grammar in:
http://github.com/ingydotnet/testml-pm6/blob/master/lib/TestML/Parser/Grammar.pm

All other implementations of TestML use this Pegex grammar:
http://github.com/ingydotnet/testml-pgx/blob/master/testml.pgx

In Perl 5, Pegex::Compiler is used to compile the grammar into this simple
data structure (shown in YAML):
http://github.com/ingydotnet/testml-pgx/testml.yaml

The grammar can also be precompiled to JSON:
http://github.com/ingydotnet/testml-pgx/testml.json

Pegex::Compiler further compiles this into a Perl 5 only graamar tree, which
becomes this module:
http://github.com/ingydotnet/testml-pm/lib/TestML/Parser/Grammar.pm

TestML::Parser::Grammar is a subclass of Pegex::Grammar. It can be used to
parse TestML files. TestML::Parser calls the C<parse()> method of the grammar
with a TestML::Receiver object that receives callbacks when various rules
match, and uses the information to build a TestML::Document object.
http://github.com/ingydotnet/testml-pm/lib/TestML/Parser.pm
