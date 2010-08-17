package Pegex::Compiler::Grammar;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub grammar_tree {
    return +{
  '_FIRST_RULE' => 'grammar',
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
  'regular_expression' => {
    '+re' => qr/(?-xism:\G\/([^\/]*)\/)/
  },
  'rule_alternation' => {
    '+all' => [
      {
        '+rule' => 'rule_set'
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G\s*\|\s*)/
          },
          {
            '+rule' => 'rule_set'
          }
        ],
        '<' => '+'
      }
    ]
  },
  'rule_definition' => {
    '+all' => [
      {
        '+rule' => 'rule_name'
      },
      {
        '+re' => qr/(?-xism:\G[\ \t]*:\s*)/
      },
      {
        '+rule' => 'rule_set'
      },
      {
        '+rule' => 'rule_ending'
      }
    ]
  },
  'rule_ending' => {
    '+re' => qr/(?-xism:\G\s*[\n|;])/
  },
  'rule_group' => {
    '+any' => [
      {
        '+rule' => 'rule_sequence'
      },
      {
        '+rule' => 'rule_alternation'
      }
    ]
  },
  'rule_name' => {
    '+re' => qr/(?-xism:\G([a-zA-Z]\w*))/
  },
  'rule_reference' => {
    '+re' => qr/(?-xism:\G<([!&]?)(([a-zA-Z]\w*))>)/
  },
  'rule_sequence' => {
    '+all' => [
      {
        '+rule' => 'rule_set'
      },
      {
        '+all' => [
          {
            '+re' => qr/(?-xism:\G\s*)/
          },
          {
            '+rule' => 'rule_set',
            '<' => '+'
          },
          {
            '+re' => qr/(?-xism:\G\s*)/
          }
        ]
      }
    ]
  },
  'rule_set' => {
    '+any' => [
      {
        '+rule' => 'regular_expression'
      },
      {
        '+rule' => 'rule_reference'
      },
      {
        '+rule' => 'bracketed_group'
      },
      {
        '+rule' => 'rule_group'
      }
    ]
  }
};
}

1;
