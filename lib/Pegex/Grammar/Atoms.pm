package Pegex::Grammar::Atoms;
use Pegex::Base;

#------------------------------------------------------------------------------#
# Pegex regex atoms for grammars
#------------------------------------------------------------------------------#
my $atoms = {
    # Default whitespace rules for that use '~'
    ws      => '<WS>',
    ws1     => '<ws>*',
    ws2     => '<ws>+',

    # Default whitespace rules for that use '-' and '+'
    _       => '<ws1>',
    __      => '<ws2>',

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
    EMPTY   => '',          # Empty string

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
    TICK    => "'",
    DOUBLE  => '"',
    GRAVE   => '`',
    LPAREN  => '\(',
    RPAREN  => '\)',
    LCURLY  => '\{',
    RCURLY  => '\}',
    LSQUARE => '\[',
    RSQUARE => '\]',
    LANGLE  => '<',
    RANGLE  => '\>',

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
    FF      => '\x0C',    # Formfeed
};

sub atoms { return $atoms }

1;
