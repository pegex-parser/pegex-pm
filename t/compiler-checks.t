use TestML;

TestML->new(
    testml => 'testml/compiler-checks.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
