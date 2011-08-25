use Test::More tests => 1;

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
    <street_line>
    <city_line>
    <country_line>?
street_line: /<BLANK><BLANK>/ <street> <EOL>
street: /<NS><ANY>*/
city_line: /<BLANK><BLANK>/ <city> <EOL>
city: /<NS><ANY>*/
country_line: /<BLANK><BLANK>/ <country> <EOL>
country: /<NS><ANY>*/
...

my $text1 = <<'...';
Name: Ingy Net
Phone: 919-876-5432
Address:
  1234 Main St
  Niceville
  OK
...

my $ast1 = <<'...';
...

use Pegex::Grammar;
use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;
eval {
    Pegex::Grammar->new(
#         tree => Pegex::Compiler
        tree => Pegex::Compiler::Bootstrap
            ->new(debug => 0)
            ->compile($grammar1)
            ->tree
    )->parse($text1);
}; $@
? fail $@
: pass 'Grammar compiled and parsed the address text';
