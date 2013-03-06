use TestML;

TestML->new(
    testml => 'testml/error.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
