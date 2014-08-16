use strict;
use lib (-e 't' ? 't' : 'test'), 'inc';
use TestML;
use TestML::Compiler::Lite;
use TestMLBridge;

TestML->new(
    testml => 'testml/compiler-checks.tml',
    bridge => 'TestMLBridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
