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
      '.all' => [
        {
          '.ref' => 'rule_part'
        },
        {
          '+min' => 1,
          '.all' => [
            {
              '.rgx' => qr/(?-xism:\G\s*\|\s*)/
            },
            {
              '.ref' => 'rule_part'
            }
          ]
        }
      ]
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
    'error_message' => {
      '.rgx' => qr/(?-xism:\G`([^`\r\n]*)`)/
    },
    'grammar' => {
      '.all' => [
        {
          '+min' => 1,
          '.all' => [
            {
              '+min' => 0,
              '-skip' => 1,
              '.ref' => 'comment'
            },
            {
              '.ref' => 'rule_definition'
            }
          ]
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.ref' => 'comment'
        }
      ]
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
          '.ref' => 'rule_ending'
        }
      ]
    },
    'rule_ending' => {
      '.rgx' => qr/(?-xism:\G\s*?(?:\n\s*|;\s*|\z))/
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
        '.rgx' => qr/(?-xism:\G\s*\s(%%?)\s\s*)/
      }
    },
    'rule_reference' => {
      '.rgx' => qr/(?-xism:\G([!=\+\-\.]?)<([a-zA-Z]\w*)>((?:[\*\+\?]|[0-9]+(?:\-[0-9]+|\+)?)?))/
    }
  }
}

1;
