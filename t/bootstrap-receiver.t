# BEGIN { $Pegex::Parser::Debug = 1 }
use t::TestPegex;

use Pegex::Parser;
use Pegex::Grammar;

sub run {
    my $block = shift;
    my ($text, $input, $ast) = @{$block->{points}}{qw(grammar input ast)};
    my $receiver = $block->{receiver};
    my $grammar = Pegex::Grammar->new(text => $text);
    my $parser = Pegex::Parser->new(
        grammar => $grammar,
        receiver => $receiver,
    );
    my $out = fixup(yaml($parser->parse($input)));
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
  receiver: t::TestPegex::AST
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
  receiver: Pegex::Tree::Wrap
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
