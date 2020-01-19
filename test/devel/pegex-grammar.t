use strict;
use warnings;
use Test::More;
use lib -e 'xt' ? 'xt' : 'test/devel';
use TestDevelPegex;

eval "use YAML::XS; 1" or
    plan skip_all => 'YAML::XS required';

my $PGX = 'Pegex::Pegex::Grammar';
my $parser = do {
  {
    require Pegex::Pegex::Grammar;
    $PGX->compile_into_module;
    local $SIG{__WARN__} = sub { };
    delete $INC{'Pegex/Pegex/Grammar.pm'};
    require Pegex::Pegex::Grammar;
  }
  pegex_parser_ast;
};

my $pgx_ast = $parser->parse($PGX->text);

my $got = YAML::XS::Dump($pgx_ast);

my $expected = join '', <DATA>;
#open my $fh, '>', 'tf'; print $fh explain $got; # uncomment to regenerate
is $got, $expected, 'self-AST as expected' or diag explain $got;

__DATA__
---
+grammar: pegex
+include: pegex-atoms
+toprule: grammar
+version: 0.2.0
ERROR_all_group:
  .all:
  - .ref: ERROR_rule_part
  - +min: 0
    -flat: 1
    .all:
    - .ref: _
    - .ref: ERROR_rule_part
ERROR_any_group:
  .all:
  - .ref: ERROR_all_group
  - +min: 1
    -flat: 1
    .all:
    - .rtr:
      - .ref: _
      - .ref: PIPE
      - .ref: _
    - .ref: ERROR_all_group
ERROR_bracketed_group:
  .any:
  - .all:
    - .rtr:
      - .rgx: (!
      - .ref: group-modifier
      - .rgx: )
      - .rgx: (=
      - .ref: illegal-non-modifier-char
      - .ref: LPAREN
      - .rgx: )
    - .err: Illegal group rule modifier (can only use .)
  - .all:
    - .rtr:
      - .rgx: (
      - .ref: group-modifier
      - .rgx: '?'
      - .rgx: )
      - .ref: LPAREN
      - .ref: _
    - .ref: rule_group
    - .any:
      - .all:
        - +asr: 1
          .ref: doc_ending
        - .err: Runaway rule group; no ending parens at EOF
      - .all:
        - .rtr:
          - .rgx: (=
          - .ref: _
          - .ref: RPAREN
          - .ref: illegal-non-quantifier-char
          - .rgx: )
        - .err: Illegal character in group rule quantifier
ERROR_error_message:
  .any:
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: GRAVE
      - .rgx: '[^'
      - .ref: GRAVE
      - .ref: DOS
      - .rgx: ']*'
      - .rgx: '['
      - .ref: DOS
      - .rgx: ']'
      - .rgx: '[^'
      - .ref: GRAVE
      - .rgx: ']*'
      - .ref: GRAVE
      - .rgx: )
    - .err: Multi-line error messages not allowed!
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: GRAVE
      - .rgx: '[^'
      - .ref: GRAVE
      - .rgx: ']*'
      - .ref: doc-ending
      - .rgx: )
    - .err: Runaway error message; no ending grave at EOF
ERROR_meta_definition:
  .all:
  - .rtr:
    - .rgx: (=
    - .ref: PERCENT
    - .ref: WORD
    - .rgx: +
    - .rgx: )
  - .err: Illegal meta rule
ERROR_regular_expression:
  .all:
  - .rtr:
    - .rgx: (=
    - .ref: SLASH
    - .rgx: (
    - .rgx: '[^'
    - .ref: SLASH
    - .rgx: ']*'
    - .rgx: )
    - .ref: doc-ending
    - .rgx: )
  - .err: Runaway regular expression; no ending slash at EOF
ERROR_rule_definition:
  .all:
  - .ref: ERROR_rule_start
  - .ref: ERROR_rule_group
  - .any:
    - .ref: ending
    - .err: Rule ending syntax error
ERROR_rule_group:
  .any:
  - .ref: ERROR_any_group
  - .ref: ERROR_all_group
ERROR_rule_item:
  .any:
  - .ref: rule_item
  - .ref: ERROR_rule_reference
  - .ref: ERROR_regular_expression
  - .ref: ERROR_bracketed_group
  - .ref: ERROR_error_message
ERROR_rule_part:
  .all:
  - .ref: ERROR_rule_item
  - +max: 1
    +min: 0
    -flat: 1
    .all:
    - .rtr:
      - .ref: __
      - .rgx: (
      - .ref: PERCENT
      - .rgx: '{1,2}'
      - .rgx: )
      - .ref: __
    - .ref: ERROR_rule_item
ERROR_rule_reference:
  .any:
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: rule-modifier
      - .rgx: '?'
      - .ref: LANGLE
      - .ref: rule-name
      - .rgx: (!
      - .ref: RANGLE
      - .rgx: )
      - .rgx: )
    - .err: Missing > in rule reference
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: rule-modifier
      - .rgx: '?'
      - .ref: rule-name
      - .ref: RANGLE
      - .rgx: )
    - .err: Missing < in rule reference
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: rule-modifier
      - .rgx: '?'
      - .rgx: '(:'
      - .ref: rule-name
      - .rgx: '|'
      - .ref: LANGLE
      - .ref: rule-name
      - .ref: RANGLE
      - .rgx: )
      - .ref: illegal-non-quantifier-char
      - .rgx: )
    - .err: Illegal character in rule quantifier
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: rule-modifier
      - .rgx: '?'
      - .ref: rule-name
      - .ref: DASH
      - .rgx: )
    - .err: Unprotected rule name with numeric quantifier; please use <rule>#-# syntax!
  - .all:
    - +asr: -1
      .ref: rule_modifier
    - .rtr:
      - .rgx: (=
      - .ref: illegal-non-modifier-char
      - .rgx: '(:'
      - .ref: rule-name
      - .rgx: '|'
      - .ref: LANGLE
      - .ref: rule-name
      - .ref: RANGLE
      - .rgx: )
      - .ref: rule-quantifier
      - .rgx: '?'
      - .rgx: (!
      - .ref: BLANK
      - .rgx: '*'
      - .ref: COLON
      - .rgx: )
      - .rgx: )
    - .err: Illegal rule modifier (must be [=!.-+]?)
ERROR_rule_start:
  .any:
  - .rtr:
    - .rgx: (
    - .ref: rule-name
    - .rgx: )
    - .ref: BLANK
    - .rgx: '*'
    - .ref: COLON
    - .ref: _
  - .err: Rule header syntax error
ERROR_separation:
  .any:
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: _
      - .ref: PERCENT
      - .rgx: '{3}'
      - .rgx: )
    - .err: Leading separator form (BOK) no longer supported
  - .all:
    - .rtr:
      - .rgx: (=
      - .ref: _
      - .ref: PERCENT
      - .rgx: '{1,2}'
      - .rgx: '[^'
      - .ref: WS
      - .rgx: ']'
      - .rgx: )
    - .err: Illegal characters in separator indicator
all_group:
  .all:
  - .ref: rule_part
  - +min: 0
    .all:
    - .ref: _
    - .ref: rule_part
any_group:
  .all:
  - .rtr:
    - .ref: _
    - .lit: '|'
    - .rgx: '?'
    - .ref: _
  - .ref: all_group
  - +min: 0
    .all:
    - .rtr:
      - .ref: _
      - .lit: '|'
      - .ref: _
    - .ref: all_group
bracketed_group:
  .all:
  - .rtr:
    - .rgx: (
    - .ref: group-modifier
    - .rgx: '?'
    - .rgx: )
    - .lit: (
    - .ref: _
  - .ref: rule_group
  - .rtr:
    - .ref: _
    - .lit: )
    - .rgx: (
    - .ref: rule-quantifier
    - .rgx: '?'
    - .rgx: )
comment:
  .rtr:
  - .lit: '#'
  - .ref: ANY
  - .rgx: '*'
  - .rgx: '(:'
  - .ref: BREAK
  - .rgx: '|'
  - .ref: EOS
  - .rgx: )
doc_ending:
  .rtr:
  - .ref: _
  - .ref: EOS
ending:
  .rtr:
  - .ref: _
  - .rgx: '(:'
  - .ref: BREAK
  - .ref: _
  - .ref: SEMI
  - .rgx: '?'
  - .ref: _
  - .rgx: '|'
  - .ref: comment
  - .ref: _
  - .ref: SEMI
  - .rgx: '?'
  - .ref: _
  - .rgx: '|'
  - .ref: SEMI
  - .ref: _
  - .rgx: '|'
  - .ref: EOS
  - .rgx: )
error_message:
  .rtr:
  - .lit: '`'
  - .rgx: (
  - .rgx: '[^'
  - .lit: '`'
  - .ref: DOS
  - .rgx: ']*'
  - .rgx: )
  - .lit: '`'
grammar:
  .all:
  - .ref: meta_section
  - .ref: rule_section
  - .any:
    - .ref: doc_ending
    - .ref: ERROR_rule_definition
group_modifier:
  .rtr:
  - .rgx: '['
  - .ref: DASH
  - .ref: DOT
  - .rgx: ']'
illegal_non_modifier_char:
  .rtr:
  - .rgx: '[^'
  - .ref: WORD
  - .ref: LPAREN
  - .ref: RPAREN
  - .ref: LANGLE
  - .ref: SLASH
  - .ref: TILDE
  - .ref: PIPE
  - .ref: GRAVE
  - .ref: WS
  - .rgx: ']'
illegal_non_quantifier_char:
  .rtr:
  - .rgx: '[^'
  - .ref: WORD
  - .ref: LPAREN
  - .ref: RPAREN
  - .ref: LANGLE
  - .ref: SLASH
  - .ref: TILDE
  - .ref: PIPE
  - .ref: GRAVE
  - .ref: WS
  - .ref: STAR
  - .ref: PLUS
  - .ref: QMARK
  - .ref: BANG
  - .ref: EQUAL
  - .ref: PLUS
  - .ref: DASH
  - .ref: DOT
  - .ref: COLON
  - .ref: SEMI
  - .rgx: ']'
meta_definition:
  .rtr:
  - .lit: '%'
  - .ref: meta-name
  - .ref: BLANK
  - .rgx: +
  - .ref: meta-value
meta_name:
  .rtr:
  - .rgx: (
  - .lit: grammar
  - .rgx: '|'
  - .lit: extends
  - .rgx: '|'
  - .lit: include
  - .rgx: '|'
  - .lit: version
  - .rgx: )
meta_section:
  +min: 0
  .any:
  - .ref: meta_definition
  - .ref: __
  - .ref: ERROR_meta_definition
meta_value:
  .rtr:
  - .ref: BLANK
  - .rgx: '*'
  - .rgx: (
  - .rgx: '[^'
  - .ref: SEMI
  - .ref: BREAK
  - .rgx: ']*?'
  - .rgx: )
  - .ref: BLANK
  - .rgx: '*'
  - .ref: ending
quoted_regex:
  .rtr:
  - .ref: TICK
  - .rgx: (
  - .rgx: '[^'
  - .ref: TICK
  - .rgx: ']*'
  - .rgx: )
  - .ref: TICK
regex_raw:
  .rtr:
  - .rgx: (
  - .rgx: '(:'
  - .ref: LPAREN
  - .ref: LANGLE
  - .rgx: '?'
  - .rgx: '['
  - .ref: EQUAL
  - .ref: BANG
  - .rgx: ']'
  - .rgx: )
  - .rgx: '|'
  - .rgx: (?:[^
  - .ref: WS
  - .ref: SLASH
  - .ref: TICK
  - .ref: LANGLE
  - .rgx: '])+'
  - .rgx: )
regex_rule_reference:
  .rtr:
  - .rgx: '(:'
  - .ref: __
  - .rgx: (
  - .ref: rule-name
  - .rgx: )
  - .rgx: '|'
  - .rgx: '(:'
  - .lit: <
  - .rgx: (
  - .ref: rule-name
  - .rgx: )
  - .lit: '>'
  - .rgx: )
  - .rgx: )
  - .rgx: (!
  - .ref: BLANK
  - .rgx: '*'
  - .lit: ':'
  - .rgx: )
regular_expression:
  .all:
  - .rtr:
    - .rgx: (
    - .ref: group-modifier
    - .rgx: '?'
    - .rgx: )
  - -skip: 1
    .lit: /
  - +max: 1
    .ref: whitespace_start
  - +min: 0
    .any:
    - .ref: whitespace_must
    - .ref: whitespace_maybe
    - .ref: quoted_regex
    - .ref: regex_rule_reference
    - .ref: __
    - .ref: regex_raw
  - -skip: 1
    .lit: /
rule_definition:
  .all:
  - .ref: rule_start
  - .ref: rule_group
  - .ref: ending
rule_group:
  .ref: any_group
rule_item:
  .any:
  - .ref: bracketed_group
  - .ref: whitespace_token
  - .ref: rule_reference
  - .ref: quoted_regex
  - .ref: regular_expression
  - .ref: error_message
rule_modifier:
  .rtr:
  - .rgx: '['
  - .ref: BANG
  - .ref: EQUAL
  - .ref: PLUS
  - .ref: DASH
  - .ref: DOT
  - .rgx: ']'
rule_name:
  .rtr:
  - .rgx: '(:'
  - .ref: ALPHA
  - .ref: ALNUM
  - .rgx: '*'
  - .rgx: (:[
  - .ref: DASH
  - .ref: UNDER
  - .rgx: ']'
  - .ref: ALNUM
  - .rgx: +)*
  - .rgx: '|'
  - .ref: DASH
  - .rgx: +
  - .rgx: '|'
  - .ref: UNDER
  - .rgx: +
  - .rgx: )
  - .rgx: (=
  - .rgx: '[^'
  - .ref: WORD
  - .ref: DASH
  - .rgx: '])'
rule_part:
  .all:
  - .ref: rule_item
  - +max: 1
    +min: 0
    -flat: 1
    .all:
    - .rtr:
      - .ref: __
      - .rgx: (
      - .lit: '%'
      - .rgx: '{1,2}'
      - .rgx: )
      - .ref: __
    - .ref: rule_item
rule_quantifier:
  .rtr:
  - .rgx: '(:'
  - .rgx: '['
  - .ref: STAR
  - .ref: PLUS
  - .ref: QMARK
  - .rgx: ']'
  - .rgx: '|'
  - .ref: DIGIT
  - .rgx: +
  - .rgx: '(:'
  - .ref: DASH
  - .ref: DIGIT
  - .rgx: +
  - .rgx: '|'
  - .ref: PLUS
  - .rgx: )?
  - .rgx: )
rule_reference:
  .rtr:
  - .rgx: (
  - .ref: rule-modifier
  - .rgx: '?'
  - .rgx: )
  - .rgx: '(:'
  - .rgx: (
  - .ref: rule-name
  - .rgx: )
  - .rgx: '|'
  - .rgx: '(:'
  - .lit: <
  - .rgx: (
  - .ref: rule-name
  - .rgx: )
  - .lit: '>'
  - .rgx: )
  - .rgx: )
  - .rgx: (
  - .ref: rule-quantifier
  - .rgx: '?'
  - .rgx: )
  - .rgx: (!
  - .ref: BLANK
  - .rgx: '*'
  - .lit: ':'
  - .rgx: )
rule_section:
  +min: 0
  .any:
  - .ref: rule_definition
  - .ref: __
rule_start:
  .rtr:
  - .rgx: (
  - .ref: rule-name
  - .rgx: )
  - .ref: BLANK
  - .rgx: '*'
  - .lit: ':'
  - .ref: _
whitespace_maybe:
  .rtr:
  - .ref: _
  - .ref: DASH
  - .rgx: (=
  - .rgx: '['
  - .ref: SPACE
  - .ref: SLASH
  - .ref: CR
  - .ref: NL
  - .rgx: '])'
whitespace_must:
  .rtr:
  - .ref: __
  - .rgx: '(:'
  - .ref: PLUS
  - .rgx: '|'
  - .ref: DASH
  - .ref: DASH
  - .rgx: )
  - .rgx: (=
  - .rgx: '['
  - .ref: SPACE
  - .ref: SLASH
  - .ref: CR
  - .ref: NL
  - .rgx: '])'
whitespace_start:
  .rtr:
  - .rgx: ([
  - .ref: PLUS
  - .ref: DASH
  - .rgx: '])'
  - .rgx: (!
  - .rgx: '['
  - .ref: DASH
  - .ref: TILDE
  - .rgx: '])'
whitespace_token:
  .rtr:
  - .rgx: (
  - .rgx: '(:'
  - .ref: PLUS
  - .rgx: '|'
  - .ref: DASH
  - .rgx: '|'
  - .ref: DASH
  - .ref: DASH
  - .rgx: '|'
  - .ref: TILDE
  - .rgx: '|'
  - .ref: TILDE
  - .ref: TILDE
  - .rgx: )
  - .rgx: )
  - .rgx: (=
  - .ref: __
  - .rgx: )
ws:
  .rtr:
  - .rgx: '(:'
  - .ref: WS
  - .rgx: '|'
  - .ref: comment
  - .rgx: )
