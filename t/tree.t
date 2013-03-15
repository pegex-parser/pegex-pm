use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/tree.tml',
    bridge => 'TestMLBridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
