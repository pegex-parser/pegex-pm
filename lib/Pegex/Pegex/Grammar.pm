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
    '+version' => '0.1.0',
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
    'meta_definition' => {
      '.rgx' => qr/(?-xism:\G%(grammar|extends|include|version)[\ \t]+[\ \t]*([^;\n]*?)[\ \t]*(?:\s|\#.*(?:\n|\z))*?(?:\n(?:\s|\#.*(?:\n|\z))*|;(?:\s|\#.*(?:\n|\z))*|\z))/
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
          '.ref' => 'ending'
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
        }
      ]
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
      '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*\b)[\ \t]*:(?:\s|\#.*(?:\n|\z))*)/
    },
    'whitespace_token' => {
      '.rgx' => qr/(?-xism:\G(\~+))/
    }
  }
}

1;
