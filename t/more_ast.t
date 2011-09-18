# BEGIN { $Pegex::Parser::Debug = 1 }
use t::TestPegex;

use Pegex;

sub run {
    my $block = shift;
    my ($grammar, $input, $ast) = @{$block->{points}}{qw(grammar input ast)};
#     XXX pegex($grammar)->tree;
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

plan: 10

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
      - b:
          1: bb
      - 1: cc

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
      - - b:
            1: b
      - - 1: c
        - 1: c

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

- title: Negative Assertion
  points:
    grammar: |
        a: !<b> <c>
        b: /b/
        c: /(c+)/
    input: ccc
    ast: |
      a:
        c:
          1: ccc

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
        b:
          1: b

- title: List and Separators
  points:
    grammar: |
        a: <b> <c> ** <d>
        b: /(b)/
        c: /(c+)/
        d: /(d+)/
    input: bcccdccddc
    ast: |
      a:
      - b:
          1: b
      - - c:
            1: ccc
        - d:
            1: d
        - c:
            1: cc
        - d:
            1: dd
        - c:
            1: c

- title: List without Separators
  points:
    grammar: |
        a: <c> ** <d>
        c: /(c+)/
        d: /d+/
    input: cccdccddc
    ast: |
      a:
      - c:
          1: ccc
      - c:
          1: cc
      - c:
          1: c

- title: List without Separators
  points:
    grammar: |
        a: <b> <c>? ** <d> <b>
        b: /(b)/
        c: /(c+)/
        d: /d+/
    input: bb
    ast: |
      a:
      - b:
          1: b
      - []
      - b:
          1: b

- title: Automatically Pass TOP
  points:
    grammar: |
        b: /(b)/
        TOP: <b> <c>*
        c: /(c)/
    input: bcc
    ast: |
      - b:
          1: b
      - - c:
            1: c
        - c:
            1: c

- title: Whitespace Matchers
  points:
    grammar: |
        TOP: /<ws>(<DOT>)~(<DOT>*)~/
    input: |2+
        .  
           ..    

    ast: |
      1: .
      2: ..
