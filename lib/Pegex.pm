package Pegex;
use strict;
use warnings;
use 5.008003;
use Pegex::Base -base;

our $VERSION = '0.02';
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

Pegex is a new Acmeist parsing technique.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
