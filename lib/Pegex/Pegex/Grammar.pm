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
    'ERROR_bracketed_group' => {
      '.any' => [
        {
          '.ref' => 'ERROR_bracketed_group1'
        },
        {
          '.ref' => 'ERROR_bracketed_group2'
        },
        {
          '.ref' => 'ERROR_bracketed_group3'
        }
      ]
    },
    'ERROR_bracketed_group1' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_bracketed_group1_re'
        },
        {
          '.err' => 'Illegal group rule modifier (can only use .)'
        }
      ]
    },
    'ERROR_bracketed_group1_re' => {
      '.all' => [
        {
          '+asr' => -1,
          '.ref' => 'group_modifier'
        },
        {
          '.rgx' => qr/(?-xism:\G[^\w\(\)<\/\~\|`\s]\((?:\s|\#.*(?:\n|\z))*)/
        },
        {
          '.ref' => 'rule_group'
        },
        {
          '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\))/
        }
      ]
    },
    'ERROR_bracketed_group2' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_bracketed_group2_re'
        },
        {
          '.err' => 'Runaway rule group; no ending parens at EOF'
        }
      ]
    },
    'ERROR_bracketed_group2_re' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G\.?\((?:\s|\#.*(?:\n|\z))*)/
        },
        {
          '.ref' => 'rule_group'
        },
        {
          '.ref' => 'doc_ending'
        }
      ]
    },
    'ERROR_bracketed_group3' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_bracketed_group3_re'
        },
        {
          '.err' => 'Illegal character in group rule quantifier'
        }
      ]
    },
    'ERROR_bracketed_group3_re' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G\.?\((?:\s|\#.*(?:\n|\z))*)/
        },
        {
          '.ref' => 'rule_group'
        },
        {
          '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\)[^\w\(\)<\/\~\|`\*\+\?!=\+\-\.:;\s])/
        }
      ]
    },
    'ERROR_error_message' => {
      '.any' => [
        {
          '.ref' => 'ERROR_error_message1'
        },
        {
          '.ref' => 'ERROR_error_message2'
        }
      ]
    },
    'ERROR_error_message1' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_error_message1_re'
        },
        {
          '.err' => 'Multi-line error messages not allowed!'
        }
      ]
    },
    'ERROR_error_message1_re' => {
      '.rgx' => qr/(?-xism:\G`[^`\r\n]*[\r\n][^`]*`)/
    },
    'ERROR_error_message2' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_error_message2_re'
        },
        {
          '.err' => 'Runaway error message; no ending grave at EOF'
        }
      ]
    },
    'ERROR_error_message2_re' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G`[^`]*)/
        },
        {
          '.ref' => 'doc_ending'
        }
      ]
    },
    'ERROR_meta_definition' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_meta_definition_re'
        },
        {
          '.err' => 'Illegal meta rule'
        }
      ]
    },
    'ERROR_meta_definition_re' => {
      '.rgx' => qr/(?-xism:\G%\w+)/
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
      '.ref' => 'ERROR_rule_reference1'
    },
    'ERROR_pre_rule_item' => {
      '.any' => [
        {
          '.ref' => 'ERROR_pre_rule_reference'
        },
        {
          '.ref' => 'ERROR_bracketed_group'
        }
      ]
    },
    'ERROR_pre_rule_reference' => {
      '.any' => [
        {
          '.ref' => 'ERROR_rule_reference2'
        },
        {
          '.ref' => 'ERROR_rule_reference3'
        },
        {
          '.ref' => 'ERROR_rule_reference4'
        },
        {
          '.ref' => 'ERROR_rule_reference5'
        }
      ]
    },
    'ERROR_regular_expression' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_regular_expression_re'
        },
        {
          '.err' => 'Runaway regular expression; no ending slash at EOF'
        }
      ]
    },
    'ERROR_regular_expression_re' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G\/([^\/]*))/
        },
        {
          '.ref' => 'doc_ending'
        }
      ]
    },
    'ERROR_rule_ending' => {
      '.err' => 'Rule ending syntax error'
    },
    'ERROR_rule_reference1' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_rule_reference1_re'
        },
        {
          '.err' => 'Illegal rule modifier (must be [=!.-+]?)'
        }
      ]
    },
    'ERROR_rule_reference1_re' => {
      '.all' => [
        {
          '+asr' => -1,
          '.ref' => 'rule_modifier'
        },
        {
          '.rgx' => qr/(?-xism:\G[^\w\(\)<\/\~\|`\s](?:[a-zA-Z]\w*\b|<[a-zA-Z]\w*\b>)(?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?(?![\ \t]*:))/
        }
      ]
    },
    'ERROR_rule_reference2' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_rule_reference2_re'
        },
        {
          '.err' => 'Missing > in rule reference'
        }
      ]
    },
    'ERROR_rule_reference2_re' => {
      '.rgx' => qr/(?-xism:\G[!=\+\-\.]?<[a-zA-Z]\w*\b(?!>))/
    },
    'ERROR_rule_reference3' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_rule_reference3_re'
        },
        {
          '.err' => 'Missing < in rule reference'
        }
      ]
    },
    'ERROR_rule_reference3_re' => {
      '.rgx' => qr/(?-xism:\G[!=\+\-\.]?[a-zA-Z]\w*\b>)/
    },
    'ERROR_rule_reference4' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_rule_reference4_re'
        },
        {
          '.err' => 'Illegal character in rule quantifier'
        }
      ]
    },
    'ERROR_rule_reference4_re' => {
      '.rgx' => qr/(?-xism:\G[!=\+\-\.]?(?:[a-zA-Z]\w*\b|<[a-zA-Z]\w*\b>)[^\w\(\)<\/\~\|`\*\+\?!=\+\-\.:;\s])/
    },
    'ERROR_rule_reference5' => {
      '.all' => [
        {
          '+asr' => 1,
          '.ref' => 'ERROR_rule_reference5_re'
        },
        {
          '.err' => 'Unprotected rule name with numeric quantifier; please use <rule>#-# syntax!'
        }
      ]
    },
    'ERROR_rule_reference5_re' => {
      '.rgx' => qr/(?-xism:\G[!=\+\-\.]?[a-zA-Z]\w*\b\-)/
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
          '.ref' => 'ERROR_separation1'
        },
        {
          '.ref' => 'ERROR_separation2'
        }
      ]
    },
    'ERROR_separation1' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?=(?:\s|\#.*(?:\n|\z))*%{3}))/
        },
        {
          '.err' => 'Leading separator form (BOK) no longer supported'
        }
      ]
    },
    'ERROR_separation2' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G(?=(?:\s|\#.*(?:\n|\z))*%{1,2}[^\s]))/
        },
        {
          '.err' => 'Illegal characters in separator indicator'
        }
      ]
    },
    'all_group' => {
      '+min' => 1,
      '.ref' => 'rule_part',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*)/
      }
    },
    'any_group' => {
      '+min' => '2',
      '.ref' => 'all_group',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\|(?:\s|\#.*(?:\n|\z))*)/
      }
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
          '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\)((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?))/
        }
      ]
    },
    'doc_ending' => {
      '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*\z)/
    },
    'ending' => {
      '.rgx' => qr/(?-xism:\G(?:\s|\#.*(?:\n|\z))*?(?:\n(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\z))/
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
    'group_modifier' => {
      '.rgx' => qr/(?-xism:\G\.)/
    },
    'meta_definition' => {
      '.any' => [
        {
          '.rgx' => qr/(?-xism:\G%(grammar|extends|include|version)[\ \t]+[\ \t]*([^;\n]*?)[\ \t]*(?:\s|\#.*(?:\n|\z))*?(?:\n(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\z))/
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
      '.any' => [
        {
          '.ref' => 'any_group'
        },
        {
          '.ref' => 'all_group'
        }
      ]
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
