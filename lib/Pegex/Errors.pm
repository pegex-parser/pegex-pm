package Pegex::Errors;

use Exporter 'import';

our @EXPORT;  # Set below.

use constant err_no_previous_parse =>
"Called Pegex::parse(...) with no arguments (means to continue), but no previous parse started";
sub err_deep_recursion {
"Deep recursion ($_[0] levels) on Pegex::Parser::match_next\n"}
sub err_iteration_limit {
"Pegex iteration limit of $_[0] reached."}
sub err_no_rule_defined {
"No rule defined for '$_[0]'"}
use constant err_throw_on_error_deprecated => <<'.';
Pegex::Parser: 'throw_on_error' is deprecated.
Use the 'return' attribute instead.
See Pegex::Parser.
.
use constant err_first_arg_not_input =>
"First argument to parse(...) must be an input string or Pegex::Input object";
use constant err_second_arg_not_options =>
"Second option to Pegex::parse(...) must be an options hash ref (or a start rule name)";
use constant err_invalid_parse_args =>
"Invalid arguments to Pegex::parse(...)";
sub err_invalid_parse_option {
"Invalid parse option '$_[0]'"}
use constant err_invalid_parse_input =>
"No input or invalid input for Pegex::parse(...)";
use constant err_no_starting_rule =>
"No starting rule could be found for Pegex::Parser::parse(...)";


# Export all error messages.
BEGIN {
    @EXPORT = grep /^err_/, keys %{*Pegex::Errors::};
}

1;
