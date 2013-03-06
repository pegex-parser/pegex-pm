use TestML;

TestML->new(
    testml => 'testml/tree-pegex.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
