package Pegex::Pegex::Grammar;
use Pegex::Base;
extends 'Pegex::Grammar';

# TODO:
# use re::engine::PCRE;

use constant file => '../pegex-pgx/pegex.pgx';

# sub make_tree {
#     use Pegex::Bootstrap;
#     Pegex::Bootstrap->new->compile(file)->tree;
# }

sub make_tree {
  {
    '+grammar' => 'pegex',
    '+include' => 'pegex-atoms',
    '+toprule' => 'grammar',
    '+version' => '0.2.0',
    'ERROR_all_group' => {
      '+min' => 1,
      '.ref' => 'ERROR_rule_part',
      '.sep' => {
        '.ref' => '_'
      }
    },
    'ERROR_any_group' => {
      '+min' => '2',
      '.ref' => 'ERROR_all_group',
      '.sep' => {
        '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*\|(?:\s|\#.*(?:\n|\z))*/
      }
    },
    'ERROR_bracketed_group' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?!\.)(?=[^\w\(\)<\/\~\|`\s]\()/
            },
            {
              '.err' => 'Illegal group rule modifier (can only use .)'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(\.?)\((?:\s|\#.*(?:\n|\z))*/
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
                      '.err' => 'Runaway rule group. No ending parens at EOF'
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
              '.err' => 'Runaway error message. No ending grave at EOF'
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
          '.err' => 'Runaway regular expression. No ending slash at EOF'
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
      '+max' => '2',
      '+min' => '1',
      '.ref' => 'ERROR_rule_item',
      '.sep' => {
        '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))+(%{1,2})(?:\s|\#.*(?:\n|\z))+/
      }
    },
    'ERROR_rule_reference' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=[!=\+\-\.]?<(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])(?!>))/
            },
            {
              '.err' => 'Missing > in rule reference'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=[!=\+\-\.]?(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])>)/
            },
            {
              '.err' => 'Missing < in rule reference'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?=[!=\+\-\.]?(?:(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])|<(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])>)[^\w\(\)<\/\~\|`\s\*\+\?!=\+\-\.:;])/
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
              '.err' => 'Unprotected rule name with numeric quantifier. Please use <rule>#-# syntax!'
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
              '.rgx' => qr/\G(?=[^\w\(\)<\/\~\|`\s](?:(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])|<(?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-])>)(?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?(?![\ \t]*:))/
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
          '.rgx' => qr/\G(\.?)\((?:\s|\#.*(?:\n|\z))*/
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
      '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))*?(?:\n(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|\#.*(?:\n|\z)(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\z)/
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
      '.rgx' => qr/\G%(grammar|extends|include|version)[\ \t]+[\ \t]*([^;\n]*?)[\ \t]*(?:\s|\#.*(?:\n|\z))*?(?:\n(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|\#.*(?:\n|\z)(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\z)/
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
    'regular_expression' => {
      '.rgx' => qr/\G\/([^\/]*)\//
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
          '.ref' => 'whitespace_token'
        },
        {
          '.ref' => 'rule_reference'
        },
        {
          '.ref' => 'regular_expression'
        },
        {
          '.ref' => 'bracketed_group'
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
      '+max' => '2',
      '+min' => '1',
      '.ref' => 'rule_item',
      '.sep' => {
        '.rgx' => qr/\G(?:\s|\#.*(?:\n|\z))+(%{1,2})(?:\s|\#.*(?:\n|\z))+/
      }
    },
    'rule_reference' => {
      '.rgx' => qr/\G([!=\+\-\.]?)(?:((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))|(?:<((?:[a-zA-Z][a-zA-Z0-9]*(?:[\-_][a-zA-Z0-9]+)*|\-+|_+)(?=[^\w\-]))>))((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?)(?![\ \t]*:)/
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
    'whitespace_token' => {
      '.rgx' => qr/\G(\~+|(?:\++|\-+)(?=\s+|\z))/
    }
  }
}

1;
