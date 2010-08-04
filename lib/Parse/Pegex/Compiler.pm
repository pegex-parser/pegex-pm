package Parse::Pegex::Compiler;
use Parse::Pegex::Base -base;

use XXX;
sub compile {
    my $self = shift;
    my $grammar_text = shift;
    XXX split /(?=^\w+:\s)/m, $grammar_text;
}

1;
