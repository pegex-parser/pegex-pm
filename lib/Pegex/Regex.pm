package Pegex::Regex;

use Pegex::Parser;
use Pegex::Grammar;
use Pegex::Receiver;

my @parsers;
my $PASS = '';
my $FAIL = '(*FAIL)';

sub generate_regex {
    push @parsers, Pegex::Parser->new(
        grammar => Pegex::Grammar->new( text => shift ),
        receiver => Pegex::Receiver->new,
        throw_on_error => 0,
    );
    my $index = $#parsers;
    my $regex = "(??{Pegex::Regex::parse($index, \$_)})";
    use re 'eval';
    return qr{$regex};
}

sub parse {
    my ($index, $input) = @_;
    undef %/;
    my $ast = $parsers[$index]->parse($input) or return $FAIL;
    %/ = %$ast if ref($ast) eq 'HASH';
    return $PASS;
};

# The following code was mutated from Damian Conway's Regexp::Grammars
sub import {
    # Signal lexical scoping (active, unless something was exported)...
    $^H{'Pegex::Regex::active'} = 1;

    # Process any regexes in module's active lexical scope...
    use overload;
    overload::constant(
        qr => sub {
            my ($raw, $cooked, $type) = @_;
            # If active scope and really a regex...
            return generate_regex($raw)
                if _module_is_active() and $type =~ /qq?/;
            # Ignore everything else...
            return $cooked;
        }
    );
}

# Deactivate module's regex effect when it is "anti-imported" with 'no'...
sub unimport {
    # Signal lexical (non-)scoping...
    $^H{'Pegex::Regex::active'} = 0;
}

# Encapsulate the hoopy user-defined pragma interface...
sub _module_is_active {
    return (caller 1)[10]->{'Pegex::Regex::active'};
}

1;
