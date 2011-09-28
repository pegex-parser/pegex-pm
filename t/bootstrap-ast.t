# BEGIN { $Pegex::Parser::Debug = 1 }
# BEGIN { $Pegex::Bootstrap = 1 }
use t::TestPegex;

use Pegex;
# use XXX;

sub run {
    my $block = shift;
    my ($grammar, $input, $ast) = @{$block->{points}}{qw(grammar input ast)};
    my $out = fixup(yaml(pegex($grammar)->parse($input)));
    is $out, $ast, $block->{title};
}

sub fixup {
    my $yaml = shift;
    $yaml =~ s/\A---\s//;
    $yaml =~ s/\'(\d+)\'/$1/g;
    return $yaml;
}

sub yaml {
    return YAML::XS::Dump(shift);
}

__DATA__

plan: 16

blocks:
- title: Pass and Skip
  points:
    grammar: |
        a: <b> -<c> .<d>
        b: /(b+)/
        c: /(c+)/
        d: /(d+)/
    input: bbccdd
    ast: |
      a:
      - b: bb
      - cc

- title: Pass and Skip Multi
  points:
    grammar: |
        a: <b>* -<c>* .<d>*
        b: /(b)/
        c: /(c)/
        d: /(d)/
    input: bccdd
    ast: |
      a:
      - - b: b
      - - c
        - c

- title: Non capture Regex
  points:
    grammar: |
        a: <b> <b>* -<c>* .<d>*
        b: /b/
        c: /c+/
        d: /d/
    input: bbccdd
    ast: |
      a:
      - []
      - []

- title: Assertions
  points:
    grammar: |
        a: !<b> =<c> <c>
        b: /b/
        c: /(c+)/
    input: ccc
    ast: |
      a:
        c: ccc

- title: Skip Bracketed
  points:
    grammar: |
        a: <b> .[ <c> <d> ]
        b: /(b)/
        c: /(c+)/
        d: /(d+)/
    input: bcccd
    ast: |
      a:
        b: b

- title: List and Separators
  points:
    grammar: |
        a: <b> <c>+ % <d>
        b: /(b)/
        c: /(c+)/
        d: /(d+)/
    input: bcccdccddc
    ast: |
      a:
      - b: b
      - - c: ccc
        - d: d
        - c: cc
        - d: dd
        - c: c

- title: List without Separators
  points:
    grammar: |
        a: <c>* % <d>
        c: /(c+)/
        d: /d+/
    input: cccdccddc
    ast: |
      a:
      - c: ccc
      - c: cc
      - c: c

- title: List without Separators
  points:
    grammar: |
        a: <b> <c>* % <d> <b>
        b: /(b)/
        c: /(c+)/
        d: /d+/
    input: bb
    ast: |
      a:
      - b: b
      - []
      - b: b

- title: Automatically Pass TOP
  points:
    grammar: |
        b: /(b)/
        TOP: <b> <c>*
        c: /(c)/
    input: bcc
    ast: |
      - b: b
      - - c: c
        - c: c

- title: Multi Group Regex
  points:
    grammar: |
        t: /.*(x).*(y).*(z).*/
    input: aaaxbbbyccczddd
    ast: |
      t:
      - x
      - y
      - z

- title: Whitespace Matchers
  points:
    grammar: |
        TOP: /<ws>(<DOT>)~(<DOT>*)~/
    input: |2+
        .  
           ..    

    ast: |
      - .
      - ..

- title: Empty Stars
  points:
    grammar: |
        a: [ <b>* <c> ]+ <b>*
        b: /(b)/
        c: /(c+)/
    input: cc
    ast: |
      a:
      - - - []
          - c: cc
      - []

- title: Exact Quantifier
  points:
    grammar: |
        a: <b>3
        b: /(b)/
    input: bbb
    ast: |
      a:
      - b: b
      - b: b
      - b: b

- title: Quantifier with Separator
  points:
    grammar: |
        a: <b>2-4 %% /,/
        b: /(b)/
    input: b,b,b,
    ast: |
      a:
      - b: b
      - b: b
      - b: b

- title: Quantifier with Separator, Trailing OK
  points:
    grammar: |
        a: <b>2-4 %% /,/
        b: /(b)/
    input: b,b,b,
    ast: |
      a:
      - b: b
      - b: b
      - b: b

- title: Quantifier on the Separator
  points:
    grammar: |
        a: <b>2-4 %% <c>*
        b: /(b)/
        c: /<COMMA>/
    input: b,b,,,,bb,
    ast: |
      a:
      - b: b
      - b: b
      - b: b
      - b: b

