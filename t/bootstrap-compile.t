use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex::Compiler::Bootstrap;
use YAML::XS;

# use Test::Differences (); use Test::Builder; *Test::Builder::is_eq = sub { my $self = shift; \&Test::Differences::eq_or_diff(@_) };

sub bootstrap_compile {
    my $grammar_text = (shift)->value;
    my $compiler = Pegex::Compiler::Bootstrap->new;
    my $tree = $compiler->compile($grammar_text)->tree;
    delete $tree->{_FIRST_RULE};
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
  +all:
  - +rule: b
  - +rule: c
    <: '*'
  <: +
b:
  +re: x
c:
  +rule: x

=== Single Rule
--- grammar
a: <x>
--- yaml
a:
  +rule: x

=== Single Rule With Trailing Modifier
--- grammar
a: <x>*
--- yaml
a:
  +rule: x
  <: '*'

=== Single Rule With Leading Modifier
--- grammar
a: =<x>
--- yaml
a:
  +rule: x
  <: =

=== Single Regex
--- grammar
a: /x/
--- yaml
a:
  +re: x

=== Single Error
--- grammar
a: `x`
--- yaml
a:
  +error: x

=== Unbracketed All Group
--- grammar
a: <x> <y>
--- yaml
a:
  +all:
  - +rule: x
  - +rule: y

=== Unbracketed Any Group
--- grammar
a: /x/ | <y> | `z`
--- yaml
a:
  +any:
  - +re: x
  - +rule: y
  - +error: z

=== Bracketed All Group
--- grammar
a: [ <x> <y> ]
--- yaml
a:
  +all:
  - +rule: x
  - +rule: y

=== Bracketed Group With Trailing Modifier
--- grammar
a: [ <x> <y> ]?
--- yaml
a:
  +all:
  - +rule: x
  - +rule: y
  <: '?'

=== Bracketed Group With Leading Modifier
--- grammar
a: ![ =<x> <y> ]
--- yaml
a:
  +all:
  - +rule: x
    <: =
  - +rule: y
  <: '!'

=== Multiple Groups
--- grammar
a: [ <x> <y> ] [ <z> | /.../ ]
--- yaml
a:
  +all:
  - +all:
    - +rule: x
    - +rule: y
  - +any:
    - +rule: z
    - +re: '...'

