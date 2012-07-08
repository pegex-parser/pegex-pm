# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex::Bootstrap;
use YAML::XS;

sub bootstrap_compile {
    my $grammar_text = (shift)->value;
    my $compiler = Pegex::Bootstrap->new;
    my $tree = $compiler->parse($grammar_text)->combinate->tree;
    delete $tree->{'+top'};
    return $tree;
}

sub yaml {
    return YAML::XS::Dump((shift)->value);
}

sub clean {
    my $yaml = (shift)->value;
    $yaml =~ s/^---\s//;
    return $yaml;
}

__DATA__
%TestML 1.0

Plan = 18;

*grammar.bootstrap_compile.yaml.clean == *yaml;

=== Empty Grammar
--- grammar
--- yaml
{}

=== Simple Grammar
--- grammar
a: [ <b> <c>* ]+
b: /x/
c: <x>

--- yaml
a:
  +min: 1
  .all:
  - .ref: b
  - +min: 0
    .ref: c
b:
  .rgx: x
c:
  .ref: x

=== Single Rule
--- grammar
a: <x>
--- yaml
a:
  .ref: x

=== Single Rule with no brackets
--- grammar
a: x
--- yaml
a:
  .ref: x

=== Single Rule With Trailing Quantifier
--- grammar
a: <x>*
--- yaml
a:
  +min: 0
  .ref: x

=== Single Rule With Trailing Quantifier (no angles)
--- grammar
a: x*
--- yaml
a:
  +min: 0
  .ref: x

=== Single Rule With Leading Assertion
--- grammar
a: =<x>
--- yaml
a:
  +asr: 1
  .ref: x

=== Single Regex
--- grammar
a: /x/
--- yaml
a:
  .rgx: x

=== Single Error
--- grammar
a: `x`
--- yaml
a:
  .err: x

=== Unbracketed All Group
--- grammar
a: <x> <y>
--- yaml
a:
  .all:
  - .ref: x
  - .ref: y

=== Unbracketed Any Group
--- grammar
a: /x/ | <y> | `z`
--- yaml
a:
  .any:
  - .rgx: x
  - .ref: y
  - .err: z

=== Bracketed All Group
--- grammar
a: [ <x> <y> ]
--- yaml
a:
  .all:
  - .ref: x
  - .ref: y

=== Bracketed Group With Trailing Modifier
--- grammar
a: [ <x> <y> ]?
--- yaml
a:
  +max: 1
  .all:
  - .ref: x
  - .ref: y

=== Bracketed Group With Leading Modifier
--- grammar
a: ![ =<x> <y> ]
--- yaml
a:
  +asr: -1
  .all:
  - +asr: 1
    .ref: x
  - .ref: y

=== Multiple Groups
--- grammar
a: [ <x> <y> ] [ <z> | /.../ ]
--- yaml
a:
  .all:
  - .all:
    - .ref: x
    - .ref: y
  - .any:
    - .ref: z
    - .rgx: '...'

=== Whitespace in Regex
--- grammar
a: /<DOT>* (<DASH>{3})
    <BANG>   <BANG>
   /
--- yaml
a:
  .rgx: \.*(\-{3})!!

=== Directives
--- grammar
\%grammar foo
\%version 1.2.3

--- yaml
+grammar: foo
+version: 1.2.3

=== Multiple Duplicate Directives
--- grammar
\%grammar foo
\%include bar
\%include baz

--- yaml
+grammar: foo
+include:
- bar
- baz
