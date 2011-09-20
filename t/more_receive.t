# BEGIN { $Pegex::Parser::Debug = 1 }
use t::TestPegex;

use Pegex::Grammar;

sub run {
    my $block = shift;
    my ($grammar, $input, $ast) = @{$block->{points}}{qw(grammar input ast)};
    my $g = Pegex::Grammar->new(
        receiver => 't::TestPegex::AST',
        text => $grammar,
    );
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

plan: 1

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
      a:
      - 0
      - ''
      - ~

