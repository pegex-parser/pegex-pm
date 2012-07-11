use Test::More;

eval "use YAML::XS; 1" or
    plan skip_all => 'YAML::XS required';

plan tests => 1;

my $grammar1 = <<'...';
contact:
    name_section
    phone_section
    address_section

name_section:
    / Name <COLON> <BLANK>+ /
    name
    EOL

name: /(<WORD>+)<BLANK>(<WORD>+)/

phone_section: /Phone<COLON><BLANK>+/ <phone_number> <EOL>
phone_number: term

address_section:
    /Address<COLON><EOL>/
    street_line
    city_line
    country_line?

street_line: indent street EOL
street: /<NS><ANY>*/
city_line: indent city EOL
city: term
country_line: indent country EOL
country: term

term: /(
    <NS>            # NS is "non-space"
    <ANY>*
)/

indent: /<BLANK>{2}/
...

my $text1 = <<'...';
Name: Ingy Net
Phone: 919-876-5432
Address:
  1234 Main St
  Niceville
  OK
...

my $want1 = <<'...';
...

use Pegex::Grammar;
use Pegex::Compiler;
my $ast1 = Pegex::Grammar->new(
    tree => Pegex::Compiler->compile($grammar1)->tree,
)->parse($text1);

pass 'parsed'; exit;

my $got1 = YAML::XS::Dump($ast1);

is $got1, $want1, 'It works';
