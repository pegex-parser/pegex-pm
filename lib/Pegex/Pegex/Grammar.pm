##
# name:      Pegex::Grammar::Pegex
# abstract:  Pegex Grammar for the Pegex Grammar Language
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011, 2012

package Pegex::Pegex::Grammar;
use Pegex::Mo;
extends 'Pegex::Grammar';

use constant file => '../pegex-pgx/pegex.pgx';

sub make_tree {
  {
    '+grammar' => 'pegex',
    '+toprule' => 'grammar',
    '+version' => '0.2.0',
    'ERROR_error_message' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=`[^`\r\n]*[\r\n][^`]*`))/
            },
            {
              '.err' => 'Multi-line error messages not allowed!'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=`[^`]*(?:\s|\#.*(?:\n|\z))*\z))/
            },
            {
              '.err' => 'Runaway error message. No ending grave at EOF'
            }
          ]
        }
      ]
    },
    'ERROR_inner_bracketed_group' => {
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
              '.rgx' => qr/(?-xism:\G(?=(?:\s|\#.*(?:\n|\z))*\)[^\w\(\)<\/\~\|`\s\*\+\?!=\+\-\.:;]))/
            },
            {
              '.err' => 'Illegal character in group rule quantifier'
            }
          ]
        }
      ]
    },
    'ERROR_meta_definition' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?=%\w+))/
        },
        {
          '.err' => 'Illegal meta rule'
        }
      ]
    },
    'ERROR_post_rule_item' => {
      '.any' => [
        {
          '.ref' => 'ERROR_post_rule_reference'
        },
        {
          '.ref' => 'ERROR_regular_expression'
        },
        {
          '.ref' => 'ERROR_error_message'
        },
        {
          '.ref' => 'ERROR_separation'
        }
      ]
    },
    'ERROR_post_rule_reference' => {
      '.all' => [
        {
          '+asr' => -1,
          '.ref' => 'rule_modifier'
        },
        {
          '.rgx' => qr/(?-xism:\G(?=[^\w\(\)<\/\~\|`\s](?:[a-zA-Z]\w*\b|<[a-zA-Z]\w*\b>)(?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?(?![\ \t]*:)))/
        },
        {
          '.err' => 'Illegal rule modifier (must be [=!.-+]?)'
        }
      ]
    },
    'ERROR_pre_bracketed_group' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?!\.)(?=[^\w\(\)<\/\~\|`\s]\())/
        },
        {
          '.err' => 'Illegal group rule modifier (can only use .)'
        }
      ]
    },
    'ERROR_pre_rule_item' => {
      '.any' => [
        {
          '.ref' => 'ERROR_pre_rule_reference'
        },
        {
          '.ref' => 'ERROR_pre_bracketed_group'
        }
      ]
    },
    'ERROR_pre_rule_reference' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=[!=\+\-\.]?<[a-zA-Z]\w*\b(?!>)))/
            },
            {
              '.err' => 'Missing > in rule reference'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=[!=\+\-\.]?[a-zA-Z]\w*\b>))/
            },
            {
              '.err' => 'Missing < in rule reference'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=[!=\+\-\.]?(?:[a-zA-Z]\w*\b|<[a-zA-Z]\w*\b>)[^\w\(\)<\/\~\|`\s\*\+\?!=\+\-\.:;]))/
            },
            {
              '.err' => 'Illegal character in rule quantifier'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=[!=\+\-\.]?[a-zA-Z]\w*\b\-))/
            },
            {
              '.err' => 'Unprotected rule name with numeric quantifier. Please use <rule>#-# syntax!'
            }
          ]
        }
      ]
    },
    'ERROR_regular_expression' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?=\/([^\/]*)(?:\s|\#.*(?:\n|\z))*\z))/
        },
        {
          '.err' => 'Runaway regular expression. No ending slash at EOF'
        }
      ]
    },
    'ERROR_rule_ending' => {
      '.err' => 'Rule ending syntax error'
    },
    'ERROR_rule_start' => {
      '.all' => [
        {
          '+asr' => -1,
          '.ref' => 'doc_ending'
        },
        {
          '.err' => 'Rule header syntax error'
        }
      ]
    },
    'ERROR_separation' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=(?:\s|\#.*(?:\n|\z))*%{3}))/
            },
            {
              '.err' => 'Leading separator form (BOK) no longer supported'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?=(?:\s|\#.*(?:\n|\z))*%{1,2}[^\s]))/
            },
            {
              '.err' => 'Illegal characters in separator indicator'
            }
          ]
        }
      ]
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
              '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*)/
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
          '.ref' => 'all_group'
        },
        {
          '+min' => 0,
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\|(?:\s|\#.*(?:\n|\z))*)/
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
          '.rgx' => qr/(?-xism:\G(\.?)\((?:\s|\#.*(?:\n|\z))*)/
        },
        {
          '.ref' => 'rule_group'
        },
        {
          '.any' => [
            {
              '.ref' => 'ERROR_inner_bracketed_group'
            },
            {
              '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\)((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?))/
            }
          ]
        }
      ]
    },
    'doc_ending' => {
      '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\z)/
    },
    'ending' => {
      '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*?(?:\n(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\#.*(?:\n|\z)(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|\z))/
    },
    'error_message' => {
      '.rgx' => qr/(?-xism:\G`([^`\r\n]*)`)/
    },
    'grammar' => {
      '.all' => [
        {
          '.ref' => 'meta_section'
        },
        {
          '.ref' => 'rule_section'
        }
      ]
    },
    'meta_definition' => {
      '.any' => [
        {
          '.rgx' => qr/(?-xism:\G%(grammar|extends|include|version)[\ \t]+[\ \t]*([^;\n]*?)[\ \t]*(?:\s|\#.*(?:\n|\z))*?(?:\n(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\#.*(?:\n|\z)(?:\s|\#.*(?:\n|\z))*;?(?:\s|\#.*(?:\n|\z))*|\z))/
        },
        {
          '.ref' => 'ERROR_meta_definition'
        }
      ]
    },
    'meta_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => 'meta_definition'
        },
        {
          '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))+)/
        }
      ]
    },
    'regular_expression' => {
      '.rgx' => qr/(?-xism:\G\/([^\/]*)\/)/
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
          '.any' => [
            {
              '.ref' => 'ending'
            },
            {
              '.ref' => 'ERROR_rule_ending'
            }
          ]
        }
      ]
    },
    'rule_group' => {
      '.ref' => 'any_group'
    },
    'rule_item' => {
      '.any' => [
        {
          '.ref' => 'ERROR_pre_rule_item'
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
          '.ref' => 'whitespace_token'
        },
        {
          '.ref' => 'error_message'
        },
        {
          '.ref' => 'ERROR_post_rule_item'
        }
      ]
    },
    'rule_modifier' => {
      '.rgx' => qr/(?-xism:\G[!=\+\-\.])/
    },
    'rule_part' => {
      '+max' => '2',
      '+min' => '1',
      '.ref' => 'rule_item',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))+(%{1,2})(?:\s|\#.*(?:\n|\z))+)/
      }
    },
    'rule_reference' => {
      '.rgx' => qr/(?-xism:\G([!=\+\-\.]?)(?:([a-zA-Z]\w*\b)|(?:<([a-zA-Z]\w*\b)>))((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?)(?![\ \t]*:))/
    },
    'rule_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => 'rule_definition'
        },
        {
          '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))+)/
        }
      ]
    },
    'rule_start' => {
      '.any' => [
        {
          '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*\b)[\ \t]*:(?:\s|\#.*(?:\n|\z))*)/
        },
        {
          '.ref' => 'ERROR_rule_start'
        }
      ]
    },
    'whitespace_token' => {
      '.rgx' => qr/(?-xism:\G(\~+))/
    }
  }
}

1;
