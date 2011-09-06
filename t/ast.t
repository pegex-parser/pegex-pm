# BEGIN { $TestML::Test::Differences = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }

use TestML -run,
    -require_or_skip => 'YAML::XS';

use Pegex;
use YAML::XS;

sub parse {
    my $grammar = (shift)->value;
    my $input = (shift)->value;
    my $pegex = pegex($grammar);
    $pegex->tree;
    $pegex->parser('Pegex::Parser2');
    $pegex->receiver('Pegex::AST2');
    return $pegex->parse($input);
}

sub yaml {
    my $data = (shift)->value;
    my $yaml = YAML::XS::Dump($data);
    $yaml =~ s/^---\s+//;
    $yaml =~ s/'(\d+)':/$1:/g;
    return $yaml;
}

__DATA__
%TestML 1.0

Plan = 10;

*grammar.parse(*input).yaml == *ast;

=== Single Regex - Single Capture
--- grammar
a: /x*(y*)z*<EOL>/
--- input
xxxyyyyzzz
--- ast
a:
  1: yyyy

=== Single Regex - Multi Capture
--- grammar
a: /(x*)(y*)(z*)<EOL>/
--- input
xxxyyyyzzz
--- ast
a:
  1: xxx
  2: yyyy
  3: zzz

=== Single Regex - No Capture
--- grammar
a: /x*y*z*<EOL>/
--- input
xxxyyyyzzz
--- ast
a: {}

=== A subrule
--- grammar
a: <b> /(y+)/ <EOL>
b: /(x+)/
--- input
xxxyyyy
--- ast
a:
- b:
    1: xxx
- 1: yyyy
- EOL: {}

=== Multi match regex in subrule
--- grammar
a: <b>
b: /(x*)y*(z*)<EOL>/
--- input
xxxyyyyzzz
--- ast
a:
  b:
    1: xxx
    2: zzz

=== Any rule group
--- grammar
a: [ <b> | <c> ]
b: /(bleh)/
c: /(x*)y*(z*)<EOL>?/
--- input
xxxyyyyzzz
--- ast
a:
  c:
    1: xxx
    2: zzz

=== + Modifier
--- grammar
a: [ <b> <c> ]+ <EOL>
b: /(x*)/
c: /(y+)/
--- input
xxyyxy
--- ast
a:
- - - b:
        1: xx
    - c:
        1: yy
  - - b:
        1: x
    - c:
        1: y
- EOL: {}

=== Empty regex group plus rule
--- grammar
a: <b>* <c> <EOL>
b: /xxx/
c: /(yyy)/
--- input
xxxyyy
--- ast
a:
- - b: {}
- c:
    1: yyy
- EOL: {}


=== Part of Pegex Grammar
--- grammar
\# This is the Pegex grammar for Pegex grammars!
grammar: [ <comment>* <rule_definition> ]+ <comment>*
rule_definition: /<WS>*/ <rule_name> /<COLON><WS>*/ <rule_line>
rule_name: /(<ALPHA><WORD>*)/
comment: /<HASH><line><EOL>/
line: /<ANY>*/
rule_line: /(<line>)<EOL>/

--- input
\# This is the Pegex grammar for Pegex grammars!
grammar: [ <comment>* <rule_definition> ]+ <comment>*
rule_definition: /<WS>*/ <rule_name> /<COLON><WS>*/ <rule_line>
--- ast
grammar:
- - - - comment: {}
    - rule_definition:
      - {}
      - rule_name:
          1: grammar
      - {}
      - rule_line:
          1: '[ <comment>* <rule_definition> ]+ <comment>*'
  - - []
    - rule_definition:
      - {}
      - rule_name:
          1: rule_definition
      - {}
      - rule_line:
          1: /<WS>*/ <rule_name> /<COLON><WS>*/ <rule_line>
- []


=== Rule to Rule to Rule
--- LAST
--- grammar
a: <b>
b: <c>*
c: <d> <EOL>
d: /x(y)z/
--- input
xyz
xyz
--- ast
a:
  b:
  - c:
    - d:
        1: y
    - EOL: {}
  - c:
    - d:
        1: y
    - EOL: {}

