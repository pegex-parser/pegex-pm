# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex::Compiler::Bootstrap;
use YAML::XS;

sub bootstrap_compile {
    my $grammar_text = (shift)->value;
    my $compiler = Pegex::Compiler::Bootstrap->new;
    my $tree = $compiler->compile_raw($grammar_text)->tree;
    delete $tree->{'+top'};
    return $tree;
}

sub yaml {
    return YAML::XS::Dump((shift)->value);
}

sub clean {
    my $yaml = (shift)->value;
    $yaml =~ s/^---\n//;
    return $yaml;
}

__DATA__
%TestML 1.0

Plan = 12;

*grammar.bootstrap_compile.yaml.clean == *yaml;


=== Simple Grammar
--- grammar
a: [ <b> <c>* ]+
b: /x/
c: <x>

--- yaml
a:
  +mod: +
  .all:
  - .ref: b
  - +mod: '*'
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

=== Single Rule With Trailing Modifier
--- grammar
a: <x>*
--- yaml
a:
  +mod: '*'
  .ref: x

=== Single Rule With Leading Modifier
--- grammar
a: =<x>
--- yaml
a:
  +mod: =
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
  +mod: '?'
  .all:
  - .ref: x
  - .ref: y

=== Bracketed Group With Leading Modifier
--- grammar
a: ![ =<x> <y> ]
--- yaml
a:
  +mod: '!'
  .all:
  - +mod: =
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

