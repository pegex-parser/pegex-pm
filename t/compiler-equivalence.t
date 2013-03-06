use TestML;

TestML->new(
    testml => 'testml/compiler-equivalence.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
