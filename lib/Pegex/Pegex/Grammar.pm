##
# name:      Pegex::Grammar::Pegex
# abstract:  Pegex Grammar for the Pegex Grammar Language
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Pegex::Grammar;
use Pegex::Mo;
extends 'Pegex::Grammar';

sub tree_ {
  {
    '+grammar' => 'pegex',
    '+top' => 'grammar',
    '+version' => '0.0.1',
    'all_group' => {
      '+min' => 1,
      '.ref' => 'rule_part',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G\s*)/
      }
    },
    'any_group' => {
      '+min' => '2',
      '.ref' => 'rule_part',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G\s*\|\s*)/
      }
    },
    'bracketed_group' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G([\.]?)\[\s*)/
        },
        {
          '.ref' => 'rule_group'
        },
        {
          '.rgx' => qr/(?-xism:\G\s*\]((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?))/
        }
      ]
    },
    'comment' => {
      '.rgx' => qr/(?-xism:\G(?:[\ \t]*\r?\n|\#.*\r?\n))/
    },
    'ending' => {
      '.rgx' => qr/(?-xism:\G\s*?(?:\n\s*|;\s*|\z))/
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
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G%)/
        },
        {
          '.ref' => 'meta_name'
        },
        {
          '.rgx' => qr/(?-xism:\G[\ \t]+)/
        },
        {
          '.ref' => 'meta_value'
        }
      ]
    },
    'meta_name' => {
      '.rgx' => qr/(?-xism:\G(grammar|extends|include|version))/
    },
    'meta_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => 'meta_definition'
        },
        {
          '-skip' => 1,
          '.ref' => 'comment'
        }
      ]
    },
    'meta_value' => {
      '.rgx' => qr/(?-xism:\G[\ \t]*([^;\n]*?)[\ \t]*\s*?(?:\n\s*|;\s*|\z))/
    },
    'regular_expression' => {
      '.rgx' => qr/(?-xism:\G\/([^\/\r\n]*)\/)/
    },
    'rule_definition' => {
      '.all' => [
        {
          '.rgx' => qr/(?-xism:\G\s*)/
        },
        {
          '.ref' => 'rule_name'
        },
        {
          '.rgx' => qr/(?-xism:\G[\ \t]*:\s*)/
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
    'rule_name' => {
      '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*)\b)/
    },
    'rule_part' => {
      '+max' => '2',
      '+min' => '1',
      '.ref' => 'rule_item',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G\s+(%{1,2})\s+)/
      }
    },
    'rule_reference' => {
      '.any' => [
        {
          '.rgx' => qr/(?-xism:\G([!=\+\-\.]?)<([a-zA-Z]\w*)\b>((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?))/
        },
        {
          '.rgx' => qr/(?-xism:\G([!=\+\-\.]?)([a-zA-Z]\w*)\b((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?)(?!:))/
        }
      ]
    },
    'rule_section' => {
      '+min' => 0,
      '.any' => [
        {
          '.ref' => 'rule_definition'
        },
        {
          '-skip' => 1,
          '.ref' => 'comment'
        }
      ]
    },
    'whitespace_token' => {
      '.rgx' => qr/(?-xism:\G(\~\~?))/
    }
  }
}

1;
