# BEGIN { $Pegex::Parser::Debug = 1 }
use t::TestPegex;

use Pegex::Grammar;
# use XXX;

sub run {
    my $block = shift;
    my ($grammar, $input, $ast) = @{$block->{points}}{qw(grammar input ast)};
    my $receiver = t::TestPegex::AST->new;
    my $g = Pegex::Grammar->new(
        receiver => $receiver,
        text => $grammar,
    );
    $receiver->wrap(1) if $block->{wrap};
    my $out = fixup(yaml($g->parse($input)));
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

plan: 2

blocks:
- title: False Values
  points:
    grammar: |
        a: <zero> <empty> <undef>
        zero: /(b+)/
        empty: /(c+)/
        undef: /(d+)/
    input: bbccdd
    ast: |
      - 0
      - ''
      - ~

- title: Wrap
  wrap: 1
  points:
    grammar: |
        a: <b> <c> <d>
        b: /(b+)/
        c: /(c+)/
        d: /(d+)/
    input: bbccdd
    ast: |
        a:
        - b: bb
        - c: cc
        - d: dd
