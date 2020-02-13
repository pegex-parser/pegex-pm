use strict;
use warnings;

use Test::More;

eval "use YAML::PP; 1" or
    plan skip_all => 'YAML::PP required';

plan tests => 1;

my $grammar_text = <<'...';
contact:
    name_section
    phone_section
    address_section

name_section:
    / 'Name' <COLON> <BLANK>+ /
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

my $input = <<'...';
Name: Ingy Net
Phone: 919-876-5432
Address:
  1234 Main St
  Niceville
  OK
...

my $want = <<'...';
...

use Pegex::Grammar;
use Pegex::Receiver;
use Pegex::Compiler;
my $grammar = Pegex::Grammar->new(
    tree => Pegex::Compiler->new->compile($grammar_text)->tree,
);
my $parser = Pegex::Parser->new(
    grammar => $grammar,
    receiver => Pegex::Receiver->new,
    debug => 1,
);
my $ast1 = $parser->parse($input);

pass 'parsed'; exit;

my $got = YAML::PP
    ->new(schema => ['Perl'])
    ->dump_string($ast1);

is $got, $want, 'It works';
