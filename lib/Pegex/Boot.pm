package Pegex::Boot;
use v5.10;

use Pegex::Base;
extends 'Pegex::Compiler';

use Pegex::Grammar::Atoms;

sub parse {
    my ($self, $grammar_text) = @_;

    my @tokens = $self->lex($grammar_text);
}

my $ALPHA = 'A-Za-z';
my $DIGIT = '0-9';
my $DASH  = '\-';
my $WORD  = "$DASH$ALPHA$DIGIT";
my $SPACE = '[\ \t]';
my $EOL   = '\n';
my $MOD   = '[\!\=\-\+\.]';
my $GMOD  = '\.';
my $QUANT = '(?:[\?\*\+]|\d+(?:\+|\-\d+)?)';
my $NAME  = "[$ALPHA](?:[$WORD]*[$ALPHA$DIGIT])?";
has regexes => {
    pegex => [
        [qr/\A%(grammar|version|extends|include)$SPACE+/,
            'directive-start', 'directive'],

        [qr/\A($NAME)(?=$SPACE*\:)/,
            'rule-start'],
        [qr/\A([\:])/,
            'separator'],
        [qr/\A(?:;\s+|$EOL)(?=$NAME$SPACE*\:|\z)/,
            'rule-end'],

        [qr/\A(?:\+|\~\~|\-\-)/,
            'ws2'],
        [qr/\A(?:\-|\~)/,
            'ws1'],

        [qr/\A($MOD)?($NAME|<$NAME>)($QUANT)?/,
            'rule-ref'],
        [qr/\A\//,
            'regex-start', 'regex'],
        [qr/\A\`([^\`\n]*?)\`/,
            'error-msg'],

        [qr/\A($GMOD)?\(/,
            'group-start'],
        [qr/\A\)($QUANT)?/,
            'group-end'],
        [qr/\A\|/,
            'list-alt'],
        [qr/\A(\%\%?)/,
            'list-sep'],

        [qr/\A$SPACE+/],
        [qr/\A$EOL+/],

        [qr/\A\z/,
            'pegex-end', 'end'],
    ],
    directive => [
        [qr/\A(\S.*)/,
            'value'],
        [qr/\A$EOL/,
            'directive-end', 'end']
    ],
    regex => [
        [qr/\A(?:\+|\~\~|\-\-)/,
            'ws2'],
        [qr/\A(?:\-|~)/,
            'ws1'],
        [qr/\A([^\s\/]+)/,
            'raw'],
        [qr/\A$SPACE+/],
        [qr/\A$EOL+/],
        [qr/\A\//,
            'regex-end', 'end'],
    ],
};

sub lex {
    my ($self, $grammar) = @_;

    my $tokens = $self->{tokens} = [['pegex-start']];
    my $stack = ['pegex'];
    my $pos = 0;

    OUTER: while (1) {
        # XXX $self if $main::x++ > 20;
        my $state = $stack->[-1];
        my $set = $self->{regexes}->{$state} or die "Invalid state '$state'";
        for my $entry (@$set) {
            my ($regex, $name, $scope) = @$entry;
            YYY $state, $self->phrase($grammar, $pos), $regex;
            if (substr($grammar, $pos) =~ $regex) {
                $pos += length($&);
                if ($name) {
                    no strict 'refs';
                    my @captures = map $$_, 1..$#+;
                    push @$tokens, [$name, @captures];
                    if ($scope) {
                        if ($scope eq 'end') {
                            pop @$stack;
                        }
                        else {
                            push @$stack, $scope;
                        }
                    }
                }
                last OUTER unless @$stack;
                next OUTER;
            }
        }
        my $text = substr($grammar, $pos, 50);
        $text =~ s/\n/\\n/g;
        die <<"...";
Failed to lex $state here-->$text
...
    }
    YYY $tokens;
}

sub phrase {
    my ($self, $grammar, $pos) = @_;
    my $text = substr($grammar, $pos, 50);
    $text =~ s/\n/\\n/g;
    return $text;
}

1;
