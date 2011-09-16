# BEGIN { $Pegex::Parser::Debug = 1 }
use bt::Test;

use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;
use XXX;

sub run {
    my $block = shift;
    my $title = $block->{title};
    my $grammar = $block->{points}{grammar};
    my $compile = $block->{points}{compile};
    my $boot_compile = fixup(yaml(bootstrap_compile($grammar)));
    is $boot_compile, $compile, "$title - Bootstrap compile is correct";
#     my $pegex_compile = fixup(yaml(pegex_compile($grammar)));
#     is $pegex_compile, $compile, "$title - Pegex compile is correct";
}

sub pegex_compile {
    my $grammar_text = shift;
    Pegex::Compiler->new->parse($grammar_text)->tree;
}

sub bootstrap_compile {
    my $grammar_text = shift;
    Pegex::Compiler::Bootstrap->new->parse($grammar_text)->tree;
}

sub fixup {
    my $yaml = shift;
    $yaml =~ s/\A---\s\+top.*\n//;
    return $yaml;
}

sub yaml {
    return YAML::XS::Dump(shift);
}

__DATA__

plan: 4

blocks:
- title: Skip and Pass Marker
  points:
    grammar: |
        a: .<b> -<c>+
    compile: |
        a:
          .all:
          - -skip: 1
            .ref: b
          - +qty: +
            -pass: 1
            .ref: c

- title: List Separator
  points:
    grammar: |
        a: <b> | <c> ** <d>
    compile: |
        a:
          .any:
          - .ref: b
          - .ref: c
            .sep:
              .ref: d

- title: Ref Quantifier
  points:
    grammar: |
        a: <b>*
    compile: |
        a:
          +qty: '*'
          .ref: b

- title: Negative Assertion
  points:
    grammar: |
      a: !<b>
    compile: |
      a:
        +neg: 1
        .ref: b
