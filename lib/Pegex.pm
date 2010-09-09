package Pegex;
use strict;
use warnings;
use 5.008003;
use Pegex::Base -base;

our $VERSION = '0.10';
our @EXPORT = qw(pegex);

has 'grammar';

sub pegex {
    die 'Pegex::pegex takes one argument ($grammar_text)'
        unless @_ == 1;
    require Pegex::Grammar;
    return 'Pegex'->new(
        grammar => Pegex::Grammar->new(
            grammar_text => $_[0],
        ),
    );
}

sub compile {
    my $self = shift;
    $self->grammar->compile;
    return $self;
}

sub parse {
    my $self = shift;
    die 'Pegex->parse() takes one or two arguments ($input, $start_rule)'
        unless @_ >= 1 and @_ <= 2;
    return $self->grammar->parse(@_);
}

1;

=encoding utf-8

=head1 NAME

Pegex - Pegex Parser Generator

=head1 SYNOPSIS

    use Pegex;
    my $data = pegex($grammar)->parse($input);

or more explicitly:

    use Pegex::Grammar;
    use Pegex::AST;
    my $grammar = Pegex::Grammar->new(
        grammar => $grammar,
        receiver => Pegex::AST->new(),
    );
    $grammar->parse($input, 'rule_name');
    my $data = $grammar->receiver->data;

or customized explicitly:

    package MyGrammar;
    use Pegex::Grammar -base;
    has grammar_text => "some grammar text goes here";

    package MyReceiver;
    use Pegex::Receiver -base;
    got_some_rule { ... }
    got_other_rule { ... }

    package main;
    use MyReceiver;
    use MyGrammar;
    my $receiver = MyReceiver->new();
    my $grammar = MyGrammar->new(
        receiver => $receiver,
    );
    $grammar->parse($input);
    my $data = $receiver->data;

=head1 DESCRIPTION

Pegex is a Acmeist parser framework. It is a PEG parser grammar syntax, combined with PCRE compatible regular expressions as the match tokens. Pegex draws heavily from Perl 6 rules, but works equivalently in many modern programming languages.

With Pegex you can easily define new mini languages that can be easily compiled in many programming languages.

=head1 A REAL WORLD EXAMPLE

L<TestML> is a new Acmeist unit test language. It is perfect for software that needs to run equivalently in more than one language. 

TestML has a language specification grammar: http://www.testml.org/specification/language/

The Perl6 implementation of TestML uses this grammar in: http://github.com/ingydotnet/testml-pm6/blob/master/lib/TestML/Parser/Grammar.pm

All other implementations of TestML use this Pegex grammar: http://github.com/ingydotnet/testml-pgx/blob/master/testml.pgx

In Perl 5, Pegex::Compiler is used to compile the grammar into this simple data structure (shown in YAML): http://github.com/ingydotnet/testml-pgx/blob/master/grammar.yaml

The grammar can also be precompiled to JSON: http://github.com/ingydotnet/testml-pgx/blob/master/grammar.json

Pegex::Compiler further compiles this into a Perl 5 only graamar tree, which becomes this module: http://github.com/ingydotnet/testml-pm/blob/master/lib/TestML/Parser/Grammar.pm

TestML::Parser::Grammar is a subclass of Pegex::Grammar. It can be used to parse TestML files. TestML::Parser calls the C<parse()> method of the grammar with a TestML::Receiver object that receives callbacks when various rules match, and uses the information to build a TestML::Document object. http://github.com/ingydotnet/testml-pm/blob/master/lib/TestML/Parser.pm

=head1 REPOSITORY AND COMMUNITY

The Pegex module can be found on CPAN and on GitHub:
L<http://github.com/ingydotnet/pegex-pm>.

Please join the Pegex discussion on #pegex on irc.freenode.net.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
