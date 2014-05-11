use strict;
use File::Basename;
use lib dirname(__FILE__);
use TestML;
use TestML::Compiler::Lite;
use TestMLBridge;

TestML->new(
    testml => 'testml/tree.tml',
    bridge => 'TestMLBridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
