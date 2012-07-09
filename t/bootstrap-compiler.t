# BEGIN { $Pegex::Bootstrap = 1 }
# BEGIN { $Pegex::Parser::Debug = 1 }
use t::TestPegex;

use Pegex::Compiler;
use Pegex::Bootstrap;
# use XXX;

sub run {
    my $block = shift;
    my $title = $block->{title};
    my $grammar = $block->{points}{grammar};
    my $compile = $block->{points}{compile};
    my $boot_compile = fixup(yaml(bootstrap_compile($grammar)));
    is $boot_compile, $compile, "$title - Bootstrap compile is correct";
    my $pegex_compile = fixup(yaml(pegex_compile($grammar)));
    is $pegex_compile, $compile, "$title - Pegex compile is correct";
}

sub pegex_compile {
    my $grammar_text = shift;
    Pegex::Compiler->new->parse($grammar_text)->tree;
}

sub bootstrap_compile {
    my $grammar_text = shift;
    Pegex::Bootstrap->new->parse($grammar_text)->tree;
}

sub fixup {
    my $yaml = shift;
    $yaml =~ s/\A---\s//;
    $yaml =~ s/\A\+top.*\n//;
    $yaml =~ s/'(\d+)'/$1/g;
    return $yaml;
}

sub yaml {
    return YAML::XS::Dump(shift);
}

__DATA__

plan: 28

blocks:
- title: Single Regex
  points:
    grammar: |
        a: /x/
    compile: |
        a:
          .rgx: x

- title: Single Reference
  points:
    grammar: |
        a: <b>
    compile: |
        a:
          .ref: b

- title: Single Error
  points:
    grammar: |
        a: `b`
    compile: |
        a:
          .err: b

- title: Simple All Group
  points:
    grammar: |
        a: /b/ <c>
    compile: |
        a:
          .all:
          - .rgx: b
          - .ref: c

- title: Ref Quantifier
  points:
    grammar: |
        a: <b>*
    compile: |
        a:
          +min: 0
          .ref: b

- title: Negative and Positive Assertion
  points:
    grammar: |
      a: !<b> =<c>
    compile: |
      a:
        .all:
        - +asr: -1
          .ref: b
        - +asr: 1
          .ref: c

- title: Skip and Wrap Marker
  points:
    grammar: |
        a: .<b> +<c>+ -<d>?
    compile: |
        a:
          .all:
          - -skip: 1
            .ref: b
          - +min: 1
            -wrap: 1
            .ref: c
          - +max: 1
            -pass: 1
            .ref: d

- title: List Separator
  points:
    grammar: |
        a: <b> | <c> % /d/
    compile: |
        a:
          .any:
          - .ref: b
          - .ref: c
            .sep:
              .rgx: d

- title: List Separator
  points:
    grammar: |
        a: <b> | <c>? %% /d/
    compile: |
        a:
          .any:
          - .ref: b
          - +max: 1
            .ref: c
            .sep:
              +eok: 1
              .rgx: d

- title: Bracketed
  points:
    grammar: |
        a: <b> ( <c> <d> )?
    compile: |
        a:
          .all:
          - .ref: b
          - +max: 1
            .all:
            - .ref: c
            - .ref: d

- title: Skip Bracketed
  points:
    grammar: |
        a: <b> .( <c> <d> )
    compile: |
        a:
          .all:
          - .ref: b
          - -skip: 1
            .all:
            - .ref: c
            - .ref: d

- title: All Quantifier Forms
  points:
    grammar: |
        a: <b> <c>? <d>* <e>+ <f>55 <g>5+ <h>5-55
    compile: |
        a:
          .all:
          - .ref: b
          - +max: 1
            .ref: c
          - +min: 0
            .ref: d
          - +min: 1
            .ref: e
          - +max: 55
            +min: 55
            .ref: f
          - +min: 5
            .ref: g
          - +max: 55
            +min: 5
            .ref: h

- title: Separators with Quantifiers
  points:
    grammar: |
        a: <b>2+ % <c>* <d>* %% <e>2-3
    compile: |
        a:
          .all:
          - +min: 2
            .ref: b
            .sep:
              +min: 0
              .ref: c
          - +min: 0
            .ref: d
            .sep:
              +eok: 1
              +max: 3
              +min: 2
              .ref: e

- title: Meta Lines
  points:
    grammar: |
        %grammar        foo
        %version    1.1.1
        %extends bar bar  
        %include   bazzy 
        a: /b/
    compile: |
        +extends: bar bar
        +grammar: foo
        +include: bazzy
        +top: a
        +version: 1.1.1
        a:
          .rgx: b
