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
#     XXX $pegex->tree;
    $pegex->parser('Pegex::Parser2');
    $pegex->receiver('Pegex::AST2');
    return $pegex->parse($input);
}

sub yaml {
    my $data = (shift)->value;
    my $yaml = YAML::XS::Dump($data);
    $yaml =~ s/^---\s+//;
    return $yaml;
}

__DATA__
%TestML 1.0

Plan = 9;

*grammar.parse(*input).yaml == *ast;

=== Single Regex - Single Capture
--- grammar
a: /x*(y*)z*<EOL>/
--- input
xxxyyyyzzz
--- ast
a: yyyy

=== Single Regex - Multi Capture
--- grammar
a: /(x*)(y*)(z*)<EOL>/
--- input
xxxyyyyzzz
--- ast
a:
- xxx
- yyyy
- zzz

=== Single Regex - No Capture
--- grammar
a: /x*y*z*<EOL>/
--- input
xxxyyyyzzz
--- ast
[]

=== A subrule
--- grammar
a: <b> /(y+)/ <EOL>
b: /(x+)/
--- input
xxxyyyy
--- ast
a:
- b: xxx
- yyyy

=== Multi match regex in subrule
--- grammar
a: <b>
b: /(x*)y*(z*)<EOL>/
--- input
xxxyyyyzzz
--- ast
a:
  b:
  - xxx
  - zzz

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
  - xxx
  - zzz

=== + Modifier
--- grammar
a: [ <b> <c> ]+ <EOL>
b: /(x*)/
c: /(y+)/
--- input
xxyyxy
--- ast
a:
- - b: xx
  - c: yy
- - b: x
  - c: y

=== Empty regex group plus rule
--- grammar
a: <b>* <c> <EOL>
b: /xxx/
c: /(yyy)/
--- input
xxxyyy
--- ast
a:
  c: yyy

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
- - []
  - rule_definition:
    - rule_name: grammar
    - rule_line: '[ <comment>* <rule_definition> ]+ <comment>*'
- rule_definition:
  - rule_name: rule_definition
  - rule_line: /<WS>*/ <rule_name> /<COLON><WS>*/ <rule_line>
