use Test::More 0.88;
use Pegex::Compiler;

my $text = <<'EOF';
all: /\x{FEFF}/
EOF
my $compiler = Pegex::Compiler->new;
my $compiled = $compiler->compile($text);
ok $compiled->tree, 'compiled';

my $perl = $compiled->to_perl;
unlike $perl, qr#/u$#m, 'no /u';

done_testing;
