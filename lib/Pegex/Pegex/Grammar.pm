package Pegex::Pegex::Grammar;
use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => 'ext/pegex-pgx/pegex.pgx';

# sub make_tree {
#     use Pegex::Bootstrap;
#     use IO::All;
#     my $grammar = io->file(file)->all;
#     Pegex::Bootstrap->new->compile($grammar)->tree;
# }

sub text {   # Generated/Inlined by Pegex::Grammar (0.72)
<<'...';
# This is the Pegex grammar for Pegex grammars!

%grammar pegex
%version 0.2.0
%include pegex-atoms


grammar:
  meta-section
  rule-section
  ( doc-ending | ERROR-rule-definition )

meta-section: ( meta-definition | + | ERROR-meta-definition )*

rule-section: ( rule-definition | + )*

meta-definition: / '%' meta-name BLANK+ meta-value /

rule-definition: rule-start rule-group ending

rule-start: / ( rule-name ) BLANK* ':' -/

rule-group: any-group

any-group: /- '|'? -/ all-group ( /- '|' -/ all-group )*

all-group: rule-part (- rule-part)*

rule-part: (rule-item)1-2 % /+ ( '%'{1,2} ) +/

rule-item:
  | bracketed-group
  | whitespace-token
  | rule-reference
  | quoted-regex
  | regular-expression
  | error-message

rule-reference:
  /
    ( rule-modifier? )      # [=!.-+]
      (:                    # foo | <foo>
        ( rule-name ) |
        (: '<' ( rule-name ) '>' )
      )
    ( rule-quantifier? )    # [?*+] 2+ 2-3
    (! BLANK* ':' )         # Avoid parsing 'foo:'
  /                        # as a rule reference.

quoted-regex:
  / TICK ( [^ TICK ]* ) TICK /

regular-expression:
  /( group-modifier? )/
  '/'
  whitespace-start?
  (
  | whitespace-must
  | whitespace-maybe
  | quoted-regex
  | regex-rule-reference
  | +
  | regex-raw
  )*
  '/'

whitespace-start: / ([ PLUS DASH]) (! [ DASH TILDE ]) /

whitespace-must: /+ (: PLUS | DASH DASH )  (= [ SPACE SLASH CR NL ]) /

whitespace-maybe: /- DASH (= [ SPACE SLASH CR NL ]) /

regex-rule-reference:
  /
    (:
      + ( rule-name ) |
      (: '<' ( rule-name ) '>' )
    )
    (! BLANK* ':' )
  /

regex-raw:
  /
    (
      '(?'? '<' |
      (?:[^ WS SLASH TICK LANGLE ])+
    )
  /

bracketed-group:
    / ( group-modifier? ) '(' -/
    rule-group
    /- ')' ( rule-quantifier? ) /

whitespace-token:
    / ( (: PLUS | DASH | DASH DASH | TILDE | TILDE TILDE ) ) (= + )/

error-message:
    / '`' ( [^ '`' DOS ]* ) '`' /

rule-modifier: / [ BANG EQUAL PLUS DASH DOT ] /

group-modifier: / [ DASH DOT ] /

rule-quantifier:
    / (:
        [ STAR PLUS QMARK ] |
        DIGIT+ (: DASH DIGIT+ | PLUS)?
    ) /

meta-name:
    / ( 'grammar' | 'extends' | 'include' | 'version' ) /

meta-value:
    /
        BLANK*
        ( [^ SEMI BREAK ]*? )
        BLANK*
        ending
    /

rule_name: /
  (:
    ALPHA ALNUM* (:[ DASH UNDER ] ALNUM+)* |
    DASH+ |
    UNDER+
  )
  (= [^ WORD DASH ])
/

ending: /
  -
  (:
    BREAK - SEMI? - |
    comment - SEMI? - |
    SEMI - |
    EOS
  )
/

ws: / (: WS | comment ) /

comment: / '#' ANY* (: BREAK | EOS ) /

###
# Pegex common error recognition and reporting:
###

doc-ending: /- EOS /

illegal-non-modifier-char: / [^
    WORD LPAREN RPAREN LANGLE SLASH TILDE PIPE GRAVE WS
] /

illegal-non-quantifier-char: / [^
    WORD LPAREN RPAREN LANGLE SLASH TILDE PIPE GRAVE WS
    STAR PLUS QMARK BANG EQUAL PLUS DASH DOT COLON SEMI
] /

ERROR-meta-definition:
    /(= PERCENT WORD+ )/
    `Illegal meta rule`

# Much of this is essentially a duplicate of the above rules, except with added
# error checking

ERROR-rule-definition: ERROR-rule-start ERROR-rule-group ( ending | `Rule ending syntax error` )

ERROR-rule-group: ERROR-any-group | ERROR-all-group

ERROR-all-group: ERROR-rule-part+ % -

ERROR-any-group: (ERROR-all-group)2+ % /- PIPE -/

ERROR-rule-part: (ERROR-rule-item)1-2 % /+ ( PERCENT{1,2} ) +/

ERROR-rule-start: / ( rule-name ) BLANK* COLON -/ | `Rule header syntax error`

ERROR-rule-item:
    rule-item |
    ERROR-rule-reference |
    ERROR-regular-expression |
    ERROR-bracketed-group |
    ERROR-error-message

# Errors - rule-reference
ERROR-rule-reference:
    /(= rule-modifier? LANGLE rule-name (! RANGLE ) )/
    `Missing > in rule reference`
|
    /(= rule-modifier? rule-name RANGLE )/
    `Missing < in rule reference`
|
    /(=
        rule-modifier? (: rule-name | LANGLE rule-name RANGLE )
        illegal-non-quantifier-char
    )/
    `Illegal character in rule quantifier`
|
    /(= rule-modifier? rule-name DASH )/
    `Unprotected rule name with numeric quantifier; please use <rule>#-# syntax!`
|
    !rule-modifier
    /(=
        illegal-non-modifier-char
        (: rule-name | LANGLE rule-name RANGLE )
        rule-quantifier?         # [?*+] 2+ 2-3
        (! BLANK* COLON )      # Avoid parsing 'foo:'
    )/                             # as a rule reference.
    `Illegal rule modifier (must be [=!.-+]?)`

# Errors - regular-expression
ERROR-regular-expression:
    /(= SLASH ( [^ SLASH ]* ) doc-ending )/
    `Runaway regular expression; no ending slash at EOF`

# Errors - bracketed-group
ERROR-bracketed-group:
    /(! group-modifier) (= illegal-non-modifier-char LPAREN )/
    `Illegal group rule modifier (can only use .)`
|
    / ( group-modifier? ) LPAREN -/
    rule-group
    (
        =doc-ending
        `Runaway rule group; no ending parens at EOF`
    |
        / (= - RPAREN illegal-non-quantifier-char ) /
        `Illegal character in group rule quantifier`
    )

# Errors - error-message
ERROR-error-message:
    /(= GRAVE [^ GRAVE DOS ]* [ DOS ] [^ GRAVE ]* GRAVE )/
    `Multi-line error messages not allowed!`
|
    /(= GRAVE [^ GRAVE ]* doc-ending )/
    `Runaway error message; no ending grave at EOF`

# Errors - separation
ERROR-separation:
    /(= - PERCENT{3} )/
    `Leading separator form (BOK) no longer supported`
|
    /(= - PERCENT{1,2} [^ WS ] )/
    `Illegal characters in separator indicator`

# vim: set lisp:
...
}

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.72)
  {
    '+grammar' => 'pegex',
    '+include' => 'pegex-atoms',
    '+toprule' => 'grammar',
    '+version' => '0.2.0',
    'ERROR_all_group' => {
      '.all' => [
        {
          '.ref' => 'ERROR_rule_part'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => '_'
            },
            {
              '.ref' => 'ERROR_rule_part'
            }
          ]
        }
      ]
    },
    'ERROR_any_group' => {
      '.all' => [
        {
          '.ref' => 'ERROR_all_group'
        },
        {
          '+min' => 1,
          '-flat' => 1,
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*\|(?:\s|\#.*(?:\n|\z))*/
            },
            {
              '.ref' => 'ERROR_all_group'
            }
          ]
        }
      ]
    },
    'ERROR_bracketed_group' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?![\-\.])(?=[^\w\(\)<\/\~\|`\s]\()/
            },
            {
              '.err' => 'Illegal group rule modifier (can only use .)'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G([\-\.]?)\((?:\s|\#.*(?:\n|\z))*/
            },
            {
              '.ref' => 'rule_group'
            },
            {
              '.any' => [
                {
                  '.all' => [
                    {
                      '+asr' => 1,
                      '.ref' => 'doc_ending'
                    },
                    {
                      '.err' => 'Runaway rule group; no ending parens at EOF'
                    }
                  ]
                },
                {
                  '.all' => [
                    {
                      '.rgx' => qr/\G(?=(?:\s|\#.*(?:\n|\z))*\)[^\w\(\)<\/\~\|`\s\*\+\?!=\+\-\.:;])/
                    },
                    {
                      '.err' => 'Illegal character in group rule quantifier'
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    'ERROR_error_message' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=`[^`\r\n]*[\r\n][^`]*`)/
            },
            {
              '.err' => 'Multi-line error messages not allowed!'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=`[^`]*(?:\s|\#.*(?:\n|\z))*\z)/
            },
            {
              '.err' => 'Runaway error message; no ending grave at EOF'
            }
          ]
        }
      ]
    },
    'ERROR_meta_definition' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?=%\w+)/
        },
        {
          '.err' => 'Illegal meta rule'
        }
      ]
    },
    'ERROR_regular_expression' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?=\/([^\/]*)(?:\s|\#.*(?:\n|\z))*\z)/
        },
        {
          '.err' => 'Runaway regular expression; no ending slash at EOF'
        }
      ]
    },
    'ERROR_rule_definition' => {
      '.all' => [
        {
          '.ref' => 'ERROR_rule_start'
        },
        {
          '.ref' => 'ERROR_rule_group'
        },
        {
          '.any' => [
            {
              '.ref' => 'ending'
            },
            {
              '.err' => 'Rule ending syntax error'
            }
          ]
        }
      ]
    },
    'ERROR_rule_group' => {
      '.any' => [
        {
          '.ref' => 'ERROR_any_group'
        },
        {
          '.ref' => 'ERROR_all_group'
        }
      ]
    },
    'ERROR_rule_item' => {
      '.any' => [
        {
          '.ref' => 'rule_item'
        },
        {
          '.ref' => 'ERROR_rule_reference'
        },
        {
          '.ref' => 'ERROR_regular_expression'
        },
        {
          '.ref' => 'ERROR_bracketed_group'
        },
        {
          '.ref' => 'ERROR_error_message'
        }
      ]
    },
    'ERROR_rule_part' => {
      '.all' => [
        {
          '.ref' => 'ERROR_rule_item'
        },
        {
          '+max' => 1,
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))+(%{1,2})(?:\s|\#.*(?:\n|\z))+/
            },
            {
              '.ref' => 'ERROR_rule_item'
            }
          ]
        }
      ]
    },
    'ERROR_rule_reference' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=[!=\+\-\.]?<(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])(?!\>))/
            },
            {
              '.err' => 'Missing > in rule reference'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=[!=\+\-\.]?(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])\>)/
            },
            {
              '.err' => 'Missing < in rule reference'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=[!=\+\-\.]?(?:(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])|<(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])\>)[^\w\(\)<\/\~\|`\s\*\+\?!=\+\-\.:;])/
            },
            {
              '.err' => 'Illegal character in rule quantifier'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=[!=\+\-\.]?(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])\-)/
            },
            {
              '.err' => 'Unprotected rule name with numeric quantifier; please use <rule>#-# syntax!'
            }
          ]
        },
        {
          '.all' => [
            {
              '+asr' => -1,
              '.ref' => 'rule_modifier'
            },
            {
              '.rgx' => qr/\G(?=[^\w\(\)<\/\~\|`\s](?:(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])|<(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])\>)(?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?(?![\ \t]*:))/
            },
            {
              '.err' => 'Illegal rule modifier (must be [=!.-+]?)'
            }
          ]
        }
      ]
    },
    'ERROR_rule_start' => {
      '.any' => [
        {
          '.rgx' => qr/\G((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))[\ \t]*:(?:\s|\#.*(?:\n|\z))*/
        },
        {
          '.err' => 'Rule header syntax error'
        }
      ]
    },
    '_' => {
      '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*/
    },
    '__' => {
      '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))+/
    },
    'all_group' => {
      '.all' => [
        {
          '.ref' => 'rule_part'
        },
        {
          '+min' => 0,
          '.all' => [
            {
              '.ref' => '_'
            },
            {
              '.ref' => 'rule_part'
            }
          ]
        }
      ]
    },
    'any_group' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*\|?(?:\s|\#.*(?:\n|\z))*/
        },
        {
          '.ref' => 'all_group'
        },
        {
          '+min' => 0,
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*\|(?:\s|\#.*(?:\n|\z))*/
            },
            {
              '.ref' => 'all_group'
            }
          ]
        }
      ]
    },
    'bracketed_group' => {
      '.all' => [
        {
          '.rgx' => qr/\G([\-\.]?)\((?:\s|\#.*(?:\n|\z))*/
        },
        {
          '.ref' => 'rule_group'
        },
        {
          '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*\)((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?)/
        }
      ]
    },
    'doc_ending' => {
      '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*\z/
    },
    'ending' => {
      '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*(?:\n(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|\#.*(?:\n|\z)(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\z)/
    },
    'error_message' => {
      '.rgx' => qr/\G`([^`\r\n]*)`/
    },
    'grammar' => {
      '.all' => [
        {
          '.ref' => 'meta_section'
        },
        {
          '.ref' => 'rule_section'
        },
        {
          '.any' => [
            {
              '.ref' => 'doc_ending'
            },
            {
              '.ref' => 'ERROR_rule_definition'
            }
          ]
        }
      ]
    },
    'meta_definition' => {
      '.rgx' => qr/\G%(grammar|extends|include|version)[\ \t]+[\ \t]*([^;\n]*?)[\ \t]*(?:\s|\#.*(?:\n|\z))*(?:\n(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|\#.*(?:\n|\z)(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\z)/
    },
    'meta_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => 'meta_definition'
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'ERROR_meta_definition'
        }
      ]
    },
    'quoted_regex' => {
      '.rgx' => qr/\G'([^']*)'/
    },
    'regex_raw' => {
      '.rgx' => qr/\G(\(\??<|(?:[^\s\/'<])+)/
    },
    'regex_rule_reference' => {
      '.rgx' => qr/\G(?:(?:\s|\#.*(?:\n|\z))+((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))|(?:<((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))\>))(?![\ \t]*:)/
    },
    'regular_expression' => {
      '.all' => [
        {
          '.rgx' => qr/\G([\-\.]?)/
        },
        {
          '.rgx' => qr/\G\//
        },
        {
          '+max' => 1,
          '.ref' => 'whitespace_start'
        },
        {
          '+min' => 0,
          '.any' => [
            {
              '.ref' => 'whitespace_must'
            },
            {
              '.ref' => 'whitespace_maybe'
            },
            {
              '.ref' => 'quoted_regex'
            },
            {
              '.ref' => 'regex_rule_reference'
            },
            {
              '.ref' => '__'
            },
            {
              '.ref' => 'regex_raw'
            }
          ]
        },
        {
          '.rgx' => qr/\G\//
        }
      ]
    },
    'rule_definition' => {
      '.all' => [
        {
          '.ref' => 'rule_start'
        },
        {
          '.ref' => 'rule_group'
        },
        {
          '.ref' => 'ending'
        }
      ]
    },
    'rule_group' => {
      '.ref' => 'any_group'
    },
    'rule_item' => {
      '.any' => [
        {
          '.ref' => 'bracketed_group'
        },
        {
          '.ref' => 'whitespace_token'
        },
        {
          '.ref' => 'rule_reference'
        },
        {
          '.ref' => 'quoted_regex'
        },
        {
          '.ref' => 'regular_expression'
        },
        {
          '.ref' => 'error_message'
        }
      ]
    },
    'rule_modifier' => {
      '.rgx' => qr/\G[!=\+\-\.]/
    },
    'rule_part' => {
      '.all' => [
        {
          '.ref' => 'rule_item'
        },
        {
          '+max' => 1,
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))+(%{1,2})(?:\s|\#.*(?:\n|\z))+/
            },
            {
              '.ref' => 'rule_item'
            }
          ]
        }
      ]
    },
    'rule_reference' => {
      '.rgx' => qr/\G([!=\+\-\.]?)(?:((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))|(?:<((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))\>))((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?)(?![\ \t]*:)/
    },
    'rule_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => 'rule_definition'
        },
        {
          '.ref' => '__'
        }
      ]
    },
    'rule_start' => {
      '.rgx' => qr/\G((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))[\ \t]*:(?:\s|\#.*(?:\n|\z))*/
    },
    'whitespace_maybe' => {
      '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*\-(?=[\ \/\r\n])/
    },
    'whitespace_must' => {
      '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))+(?:\+|\-\-)(?=[\ \/\r\n])/
    },
    'whitespace_start' => {
      '.rgx' => qr/\G([\+\-])(?![\-\~])/
    },
    'whitespace_token' => {
      '.rgx' => qr/\G((?:\+|\-|\-\-|\~|\~\~))(?=(?:\s|\#.*(?:\n|\z))+)/
    }
  }
}

1;
