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
    '+top' => 'grammar',
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
      '.ref' => 'meta_definition',
      '.sep' => {
        '+bok' => 1,
        '+eok' => 1,
        '+min' => 0,
        '-skip' => 1,
        '.ref' => 'comment'
      }
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
          '.ref' => 'error_message'
        }
      ]
    },
    'rule_name' => {
      '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*))/
    },
    'rule_part' => {
      '+max' => '2',
      '+min' => '1',
      '.ref' => 'rule_item',
      '.sep' => {
        '.rgx' => qr/(?-xism:\G\s*\s(%{1,3})\s\s*)/
      }
    },
    'rule_reference' => {
      '.rgx' => qr/(?-xism:\G([!=\+\-\.]?)<([a-zA-Z]\w*)>((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?))/
    },
    'rule_section' => {
      '+min' => 1,
      '.ref' => 'rule_definition',
      '.sep' => {
        '+bok' => 1,
        '+eok' => 1,
        '+min' => 0,
        '-skip' => 1,
        '.ref' => 'comment'
      }
    }
  }
}

1;
