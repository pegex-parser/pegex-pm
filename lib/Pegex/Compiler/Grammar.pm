##
# name:      Pegex::Compiler::Grammar
# abstract:  Pegex Grammar for a Pegex Grammar
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Compiler::Grammar;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub grammar_tree {
    return +{
  '_FIRST_RULE' => 'grammar',
  'all_group' => {
    '+all' => [
      {
        '+rule' => 'rule_item'
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G\s*)/
          },
          {
            '+rule' => 'rule_item'
          }
        ],
        '<' => '+'
      }
    ]
  },
  'any_group' => {
    '+all' => [
      {
        '+rule' => 'rule_item'
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G\s*\|\s*)/
          },
          {
            '+rule' => 'rule_item'
          }
        ],
        '<' => '+'
      }
    ]
  },
  'bracketed_group' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G\[\s*)/
      },
      {
        '+rule' => 'rule_group'
      },
      {
        '+re' => qr/(?-xism:\G\s*\])/
      },
      {
        '+rule' => 'group_quantifier',
        '<' => '?'
      }
    ]
  },
  'comment' => {
    '+re' => qr/(?-xism:\G(?:[\ \t]*\r?\n|\#.*\r?\n))/
  },
  'grammar' => {
    '+all' => [
      {
        '+all' => [
          {
            '+rule' => 'comment',
            '<' => '*'
          },
          {
            '+rule' => 'rule_definition'
          }
        ],
        '<' => '+'
      },
      {
        '+rule' => 'comment',
        '<' => '*'
      }
    ]
  },
  'group_quantifier' => {
    '+re' => qr/(?-xism:\G([\*\+\?]))/
  },
  'regular_expression' => {
    '+re' => qr/(?-xism:\G\/([^\/]*)\/)/
  },
  'rule_body' => {
    '+any' => [
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G(?=\[))/
          },
          {
            '+rule' => 'bracketed_group'
          }
        ]
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G(?=\/))/
          },
          {
            '+rule' => 'regular_expression'
          }
        ]
      },
      {
        '+rule' => 'rule_group'
      },
      {
        '+rule' => 'rule_reference'
      }
    ]
  },
  'rule_definition' => {
    '+all' => [
      {
        '+re' => qr/(?-xism:\G\s*)/
      },
      {
        '+rule' => 'rule_name'
      },
      {
        '+re' => qr/(?-xism:\G[\ \t]*:\s*)/
      },
      {
        '+rule' => 'rule_body'
      },
      {
        '+rule' => 'rule_ending'
      }
    ]
  },
  'rule_ending' => {
    '+re' => qr/(?-xism:\G\s*?(?:\n\s*|;\s*|\z))/
  },
  'rule_group' => {
    '+any' => [
      {
        '+rule' => 'any_group'
      },
      {
        '+rule' => 'all_group'
      }
    ]
  },
  'rule_item' => {
    '+any' => [
      {
        '+rule' => 'bracketed_group'
      },
      {
        '+rule' => 'regular_expression'
      },
      {
        '+rule' => 'rule_reference'
      }
    ]
  },
  'rule_name' => {
    '+re' => qr/(?-xism:\G([a-zA-Z]\w*))/
  },
  'rule_reference' => {
    '+re' => qr/(?-xism:\G<([!&]?)([a-zA-Z]\w*)>([\*\+\?]?))/
  }
};
}

1;
