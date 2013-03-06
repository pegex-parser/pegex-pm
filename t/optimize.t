use TestML;

TestML->new(
    testml => 'testml/optimize.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
