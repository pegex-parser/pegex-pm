use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/error.tml',
    bridge => 'TestMLBridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
