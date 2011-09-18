##
# name:      Pegex::Grammar::Atoms
# abstract:  Pegex Regex Atoms
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Grammar::Atoms;
use Pegex::Mo;

#------------------------------------------------------------------------------#
# Pegex regex atoms for grammars
#------------------------------------------------------------------------------#
my $atoms = {
    ws      => '<WS>*',
    ALWAYS  => '',
    NEVER   => '(?!)',
    ALL     => '[\s\S]',
    ANY     => '.',
    BLANK   => '[\ \t]',
    BLANKS  => '\ \t',
    SPACE   => ' ',
    TAB     => '\t',
    WS      => '\s',
    NS      => '\S',
    BREAK   => '\n',
    CR      => '\r',
    EOL     => '\r?\n',
    DOS     => '\r\n',
    EOS     => '\z',
    ALPHA   => '[a-zA-Z]',
    LOWER   => '[a-z]',
    UPPER   => '[A-Z]',
    DIGIT   => '[0-9]',
    XDIGIT  => '[0-9a-fA-F]',
    ALNUM   => '[a-zA-Z0-9]',
    WORD    => '\w',

    SINGLE  => "'",
    DOUBLE  => '"',
    LPAREN  => '\(',
    RPAREN  => '\)',
    LCURLY  => '\{',
    RCURLY  => '\}',
    LSQUARE => '\[',
    RSQUARE => '\]',
    LANGLE  => '<',
    RANGLE  => '>',

    BANG    => '!',
    AT      => '\@',
    HASH    => '\#',
    DOLLAR  => '\$',
    PERCENT => '%',
    CARET   => '\^',
    AMP     => '&',
    STAR    => '\*',

    TILDE   => '~',
    GRAVE   => '`',
    UNDER   => '_',
    DASH    => '\-',
    PLUS    => '\+',
    EQUAL   => '=',
    PIPE    => '\|',
    BACK    => '\\\\',
    COLON   => ':',
    SEMI    => ';',
    COMMA   => ',',
    DOT     => '\.',
    QMARK   => '\?',
    SLASH   => '/',
};

sub atoms { return $atoms }

1;

=head1 SYNOPSIS

    use Pegex::Grammar::Atoms;

=head1 DESCRIPTION

Atoms are special Pegex rules that represent the small pieces of text that you
can use to build up regular expressions. Usually they are one or two
characters.

It may seem like a waste of time to specify C<< <COLON> >> in a regex, instead
of a simple C<:>. There are three reasons this is encouraged. First is that
you are defining a grammar for a new language, and it is worth the time to be
clear and verbose. Second, using an abstraction like this can help with
portabiliity to languages with different regex engines. Finally, it makes the
grammar for Pegex so much simpler, because a C</> is always a part of the
Pegex syntax, and a C<< <SLASH> >> is part of your grammar.
