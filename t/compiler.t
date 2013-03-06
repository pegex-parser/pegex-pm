use TestML;

TestML->new(
    testml => 'testml/compiler.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
