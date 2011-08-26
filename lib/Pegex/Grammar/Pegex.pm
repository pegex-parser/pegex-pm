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

sub build_tree {
    return +{
  '+top' => 'grammar',
  'all_group' => {
    '.all' => [
      {
        '.rul' => 'rule_item'
      },
      {
        '+mod' => '+',
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G\s*)/
          },
          {
            '.rul' => 'rule_item'
          }
        ]
      }
    ]
  },
  'any_group' => {
    '.all' => [
      {
        '.rul' => 'rule_item'
      },
      {
        '+mod' => '+',
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G\s*\|\s*)/
          },
          {
            '.rul' => 'rule_item'
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
        '.rul' => 'rule_group'
      },
      {
        '.rgx' => qr/(?-xism:\G\s*\])/
      },
      {
        '+mod' => '?',
        '.rul' => 'group_quantifier'
      }
    ]
  },
  'comment' => {
    '.rgx' => qr/(?-xism:\G(?:[\ \t]*\r?\n|\#.*\r?\n))/
  },
  'grammar' => {
    '.all' => [
      {
        '+mod' => '+',
        '.all' => [
          {
            '+mod' => '*',
            '.rul' => 'comment'
          },
          {
            '.rul' => 'rule_definition'
          }
        ]
      },
      {
        '+mod' => '*',
        '.rul' => 'comment'
      }
    ]
  },
  'group_quantifier' => {
    '.rgx' => qr/(?-xism:\G([\*\+\?]))/
  },
  'regular_expression' => {
    '.rgx' => qr/(?-xism:\G\/([^\/]*)\/)/
  },
  'rule_body' => {
    '.any' => [
      {
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G(?=\[))/
          },
          {
            '.rul' => 'bracketed_group'
          }
        ]
      },
      {
        '.all' => [
          {
            '.rgx' => qr/(?-xism:\G(?=\/))/
          },
          {
            '.rul' => 'regular_expression'
          }
        ]
      },
      {
        '.rul' => 'rule_group'
      },
      {
        '.rul' => 'rule_reference'
      }
    ]
  },
  'rule_definition' => {
    '.all' => [
      {
        '.rgx' => qr/(?-xism:\G\s*)/
      },
      {
        '.rul' => 'rule_name'
      },
      {
        '.rgx' => qr/(?-xism:\G[\ \t]*:\s*)/
      },
      {
        '.rul' => 'rule_body'
      },
      {
        '.rul' => 'rule_ending'
      }
    ]
  },
  'rule_ending' => {
    '.rgx' => qr/(?-xism:\G\s*?(?:\n\s*|;\s*|\z))/
  },
  'rule_group' => {
    '.any' => [
      {
        '.rul' => 'any_group'
      },
      {
        '.rul' => 'all_group'
      }
    ]
  },
  'rule_item' => {
    '.any' => [
      {
        '.rul' => 'bracketed_group'
      },
      {
        '.rul' => 'regular_expression'
      },
      {
        '.rul' => 'rule_reference'
      }
    ]
  },
  'rule_name' => {
    '.rgx' => qr/(?-xism:\G([a-zA-Z]\w*))/
  },
  'rule_reference' => {
    '.rgx' => qr/(?-xism:\G([!&]?)<([a-zA-Z]\w*)>([\*\+\?]?))/
  }
};
}

1;
