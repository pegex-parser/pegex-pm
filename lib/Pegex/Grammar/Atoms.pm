##
# name:      Pegex::Grammar::Atoms
# abstract:  Pegex Regex Atoms
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011, 2012

package Pegex::Grammar::Atoms;
use Pegex::Mo;

#------------------------------------------------------------------------------#
# Pegex regex atoms for grammars
#------------------------------------------------------------------------------#
my $atoms = {
    # Default whitespace rules for that use '~'
    ws      => '<WS>',
    ws1     => '<ws>*',
    ws2     => '<ws>+',

    # Special rules
    ALWAYS  => '',
    NEVER   => '(?!)',

    # Basics
    ALL     => '[\s\S]',    # Every char (including newline and space)
    ANY     => '.',         # Any char (except newline)
    SPACE   => '\ ',        # ASCII space char
    TAB     => '\t',        # Horizontal tab
    WS      => '\s',        # Whitespace
    NS      => '\S',        # Not Space
    NL      => '\n',        # Newline
    BREAK   => '\n',        # Line break (more readable alias for NL)
    CR      => '\r',        # Carriage return
    EOL     => '\r?\n',     # Unix/DOS line ending
    DOS     => '\r\n',      # Windows/DOS line ending
    EOS     => '\z',        # End of stream/string/file

    # Common character classes
    WORD    => '\w',
    BLANK   => '[\ \t]',
    ALPHA   => '[a-zA-Z]',
    LOWER   => '[a-z]',
    UPPER   => '[A-Z]',
    DIGIT   => '[0-9]',
    OCTAL   => '[0-7]',
    HEX     => '[0-9a-fA-F]',
    ALNUM   => '[a-zA-Z0-9]',
    CONTROL => '[\x00-\x1f]',
    HICHAR  => '[\x7f-\x{ffff}]',

    # Ranges - for use inside character classes
    WORDS   => '0-9A-Za-z_',
    BLANKS  => '\ \t',
    ALPHAS  => 'a-zA-Z',
    LOWERS  => 'a-z',
    UPPERS  => 'A-Z',
    DIGITS  => '0-9',
    OCTALS  => '0-7',
    HEXS    => '0-9a-fA-F',
    ALNUMS  => 'a-zA-Z0-9',
    CONTROLS => '\x00-\x1f',
    HICHARS => '\x7f-\x{ffff}',

    # Paired punctuation
    SINGLE  => "'",
    DOUBLE  => '"',
    GRAVE   => '`',
    LPAREN  => '\(',
    RPAREN  => '\)',
    LCURLY  => '\{',
    RCURLY  => '\}',
    LSQUARE => '\[',
    RSQUARE => '\]',
    LANGLE  => '<',
    RANGLE  => '>',

    # Other ASCII punctuation
    BANG    => '!',
    AT      => '\@',
    HASH    => '\#',
    DOLLAR  => '\$',
    PERCENT => '%',
    CARET   => '\^',
    AMP     => '&',
    STAR    => '\*',
    TILDE   => '\~',
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

    # Special rules for named control chars
    BS      => '\x08',    # Backspace
    FF      => '\x12',    # Formfeed
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
