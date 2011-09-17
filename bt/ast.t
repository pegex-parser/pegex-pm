# BEGIN { $Pegex::Parser::Debug = 1 }
use bt::Test;

use Pegex;
use XXX;

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

plan: 16

blocks:
- title: Single Regex
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


