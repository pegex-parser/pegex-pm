##
# name:      Pegex::Grammar::Pegex
# abstract:  Pegex Grammar for the Pegex Grammar Language
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Grammar::Pegex;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub tree_ {
    return +{
  '+top' => 'grammar',
  'all_group' => {
    '.all' => [
      {
        '.ref' => 'rule_item'
      },
      {
        '+mod' => '*',
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G\s*)/
          },
          {
            '.ref' => 'rule_item'
          }
        ]
      }
    ]
  },
  'any_group' => {
    '.all' => [
      {
        '.ref' => 'rule_item'
      },
      {
        '+mod' => '+',
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G\s*\|\s*)/
          },
          {
            '.ref' => 'rule_item'
          }
        ]
      }
    ]
  },
  'bracketed_group' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G\[\s*)/
      },
      {
        '.ref' => 'rule_group'
      },
      {
        '.rgx' => qr/(?-xism:\G\s*\]([\*\+\?]?))/
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
        '+mod' => '+',
        '.all' => [
          {
            '+mod' => '*',
            '.ref' => 'comment'
          },
          {
            '.ref' => 'rule_definition'
          }
        ]
      },
      {
        '+mod' => '*',
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
  'rule_reference' => {
    '.rgx' => qr/(?-xism:\G([!=]?)<([a-zA-Z]\w*)>([\*\+\?]?))/
  }
};
}

1;
