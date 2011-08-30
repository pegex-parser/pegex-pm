use Test::More tests => 1;
# $Pegex::Grammar::Debug = 1;
use YAML::XS;

my $grammar1 = <<'...';
contact:
    <name_section>
    <phone_section>
    <address_section>

name_section: /Name<COLON><BLANK>+/ <name> <EOL>
name: /(<WORD>+)<BLANK>(<WORD>+)/

phone_section: /Phone<COLON><BLANK>+/ <phone_number> <EOL>
phone_number: /<NS><ANY>*/

address_section:
    /Address<COLON><EOL>/
    <street_line>
    <city_line>
    <country_line>?
street_line: /<BLANK><BLANK>/ <street> <EOL>
street: /<NS><ANY>*/
city_line: /<BLANK><BLANK>/ <city> <EOL>
city: /<NS><ANY>*/
country_line: /<BLANK><BLANK>/ <country> <EOL>
country: /(<NS><ANY>*)/
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
    tree => Pegex::Compiler->new->compile($grammar1)->perl->tree,
    receiver => 'Pegex::AST',
)->parse($text1);

pass 'parsed'; exit;

my $got1 = YAML::XS::Dump($ast1);

is $got1, $want1, 'AST works';
