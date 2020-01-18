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
    - .rgx: <_><PIPE><_>
    - .ref: ERROR_all_group
ERROR_bracketed_group:
  .any:
  - .all:
    - .rgx: (?!<group-modifier>)(?=<illegal-non-modifier-char><LPAREN>)
    - .err: Illegal group rule modifier (can only use .)
  - .all:
    - .rgx: (<group-modifier>?)<LPAREN><_>
    - .ref: rule_group
    - .any:
      - .all:
        - +asr: 1
          .ref: doc_ending
        - .err: Runaway rule group; no ending parens at EOF
      - .all:
        - .rgx: (?=<_><RPAREN><illegal-non-quantifier-char>)
        - .err: Illegal character in group rule quantifier
ERROR_error_message:
  .any:
  - .all:
    - .rgx: (?=<GRAVE>[^<GRAVE><DOS>]*[<DOS>][^<GRAVE>]*<GRAVE>)
    - .err: Multi-line error messages not allowed!
  - .all:
    - .rgx: (?=<GRAVE>[^<GRAVE>]*<doc-ending>)
    - .err: Runaway error message; no ending grave at EOF
ERROR_meta_definition:
  .all:
  - .rgx: (?=<PERCENT><WORD>+)
  - .err: Illegal meta rule
ERROR_regular_expression:
  .all:
  - .rgx: (?=<SLASH>([^<SLASH>]*)<doc-ending>)
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
    - .rgx: <__>(<PERCENT>{1,2})<__>
    - .ref: ERROR_rule_item
ERROR_rule_reference:
  .any:
  - .all:
    - .rgx: (?=<rule-modifier>?<LANGLE><rule-name>(?!<RANGLE>))
    - .err: Missing > in rule reference
  - .all:
    - .rgx: (?=<rule-modifier>?<rule-name><RANGLE>)
    - .err: Missing < in rule reference
  - .all:
    - .rgx: (?=<rule-modifier>?(?:<rule-name>|<LANGLE><rule-name><RANGLE>)<illegal-non-quantifier-char>)
    - .err: Illegal character in rule quantifier
  - .all:
    - .rgx: (?=<rule-modifier>?<rule-name><DASH>)
    - .err: Unprotected rule name with numeric quantifier; please use <rule>#-# syntax!
  - .all:
    - +asr: -1
      .ref: rule_modifier
    - .rgx: (?=<illegal-non-modifier-char>(?:<rule-name>|<LANGLE><rule-name><RANGLE>)<rule-quantifier>?(?!<BLANK>*<COLON>))
    - .err: Illegal rule modifier (must be [=!.-+]?)
ERROR_rule_start:
  .any:
  - .rgx: (<rule-name>)<BLANK>*<COLON><_>
  - .err: Rule header syntax error
ERROR_separation:
  .any:
  - .all:
    - .rgx: (?=<_><PERCENT>{3})
    - .err: Leading separator form (BOK) no longer supported
  - .all:
    - .rgx: (?=<_><PERCENT>{1,2}[^<WS>])
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
  - .rgx: <_>\|?<_>
  - .ref: all_group
  - +min: 0
    .all:
    - .rgx: <_>\|<_>
    - .ref: all_group
bracketed_group:
  .all:
  - .rgx: (<group-modifier>?)\(<_>
  - .ref: rule_group
  - .rgx: <_>\)(<rule-quantifier>?)
comment:
  .rgx: \#<ANY>*(?:<BREAK>|<EOS>)
doc_ending:
  .rgx: <_><EOS>
ending:
  .rgx: <_>(?:<BREAK><_><SEMI>?<_>|<comment><_><SEMI>?<_>|<SEMI><_>|<EOS>)
error_message:
  .rgx: '`([^`<DOS>]*)`'
grammar:
  .all:
  - .ref: meta_section
  - .ref: rule_section
  - .any:
    - .ref: doc_ending
    - .ref: ERROR_rule_definition
group_modifier:
  .rgx: '[<DASH><DOT>]'
illegal_non_modifier_char:
  .rgx: '[^<WORD><LPAREN><RPAREN><LANGLE><SLASH><TILDE><PIPE><GRAVE><WS>]'
illegal_non_quantifier_char:
  .rgx: '[^<WORD><LPAREN><RPAREN><LANGLE><SLASH><TILDE><PIPE><GRAVE><WS><STAR><PLUS><QMARK><BANG><EQUAL><PLUS><DASH><DOT><COLON><SEMI>]'
meta_definition:
  .rgx: '%<meta-name><BLANK>+<meta-value>'
meta_name:
  .rgx: (grammar|extends|include|version)
meta_section:
  +min: 0
  .any:
  - .ref: meta_definition
  - .ref: __
  - .ref: ERROR_meta_definition
meta_value:
  .rgx: <BLANK>*([^<SEMI><BREAK>]*?)<BLANK>*<ending>
quoted_regex:
  .rgx: <TICK>([^<TICK>]*)<TICK>
regex_raw:
  .rgx: (\(\??<|(?:[^<WS><SLASH><TICK><LANGLE>])+)
regex_rule_reference:
  .rgx: (?:<__>(<rule-name>)|(?:<(<rule-name>)\>))(?!<BLANK>*:)
regular_expression:
  .all:
  - .rgx: (<group-modifier>?)
  - -skip: 1
    .rgx: /
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
    .rgx: /
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
  .rgx: '[<BANG><EQUAL><PLUS><DASH><DOT>]'
rule_name:
  .rgx: (?:<ALPHA><ALNUM>*(?:[<DASH><UNDER>]<ALNUM>+)*|<DASH>+|<UNDER>+)(?=[^<WORD><DASH>])
rule_part:
  .all:
  - .ref: rule_item
  - +max: 1
    +min: 0
    -flat: 1
    .all:
    - .rgx: <__>(%{1,2})<__>
    - .ref: rule_item
rule_quantifier:
  .rgx: (?:[<STAR><PLUS><QMARK>]|<DIGIT>+(?:<DASH><DIGIT>+|<PLUS>)?)
rule_reference:
  .rgx: (<rule-modifier>?)(?:(<rule-name>)|(?:<(<rule-name>)\>))(<rule-quantifier>?)(?!<BLANK>*:)
rule_section:
  +min: 0
  .any:
  - .ref: rule_definition
  - .ref: __
rule_start:
  .rgx: (<rule-name>)<BLANK>*:<_>
whitespace_maybe:
  .rgx: <_><DASH>(?=[<SPACE><SLASH><CR><NL>])
whitespace_must:
  .rgx: <__>(?:<PLUS>|<DASH><DASH>)(?=[<SPACE><SLASH><CR><NL>])
whitespace_start:
  .rgx: ([<PLUS><DASH>])(?![<DASH><TILDE>])
whitespace_token:
  .rgx: ((?:<PLUS>|<DASH>|<DASH><DASH>|<TILDE>|<TILDE><TILDE>))(?=<__>)
ws:
  .rgx: (?:<WS>|<comment>)
