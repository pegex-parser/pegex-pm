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
    $pegex->parser('Pegex::Parser2');
    return $pegex->parse($input);
}

sub yaml {
    my $data = (shift)->value;
    my $yaml = YAML::XS::Dump($data);
    $yaml =~ s/^---\s//;
    return $yaml;
}

__DATA__
%TestML 1.0

Plan = 1;

*grammar.parse(*input).yaml == *ast;

=== Single Regex
--- grammar
a: /x*(y*)z*<EOL>/
--- input
xxxyyyyzzz
--- astxxx
a: yyyy
--- ast
{}

