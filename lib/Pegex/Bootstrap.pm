package Pegex::Bootstrap;
use v5.10;

use Carp qw(carp confess croak);

use Pegex::Base;
extends 'Pegex::Compiler';

use Pegex::Grammar::Atoms;

#------------------------------------------------------------------------------
# The grammar. A DSL data structure. Things with '=' are tokens.
#------------------------------------------------------------------------------
has pointer => 0;
has groups => [];
has tokens => [];
has ast => {};
has stack => [];
has grammar => {
    'grammar' => [
        '=pegex-start',
        'meta-section',
        'rule-section',
        '=pegex-end',
    ],
    'meta-section' => 'meta-directive*',
    'meta-directive' => [
        '=directive-start',
        '=directive-value',
        '=directive-end',
    ],
    'rule-section' => 'rule-definition*',
    'rule-definition' => [
        '=rule-start',
        '=rule-sep',
        'rule-group',
        '=rule-end',
    ],
    'rule-group' => 'any-group',
    'any-group' => [
        '=list-alt?',
        'all-group',
        [
            '=list-alt',
            'all-group',
            '*',
        ],
    ],
    'all-group' => 'rule-part+',
    'rule-part' => [
        'rule-item',
        [
            '=list-sep',
            'rule-item',
            '?',
        ],
    ],
    'rule-item' => [
        '|',
        '=rule-reference',
        'regular-expression',
        'bracketed-group',
        'whitespace-token',
        '=error-message',
    ],
    'regular-expression' => [
        '=regex-start',
        '=!regex-end*',
        '=regex-end',
    ],
    'bracketed-group' => [
        '=group-start',
        'rule-group',
        '=group-end',
    ],
    'whitespace-token' => [
        '|',
        '=whitespace-maybe',
        '=whitespace-must',
    ],
};

#------------------------------------------------------------------------------
# Parser logic:
#------------------------------------------------------------------------------
sub parse {
    my ($self, $grammar_text) = @_;

    $self->lex($grammar_text);
    $self->{pointer} = 0;
    $self->{tree} = {};

    $self->match_ref('grammar') || die "Bootstrap parse failed";

    return $self;
}

sub match_next {
    my ($self, $next) = @_;
    my $method;
    if (ref $next) {
        $next = [@$next];
        if ($next->[0] eq '|') {
            shift @$next;
            $method = 'match_any';
        }
        else {
            $method = 'match_all';
        }
        if ($next->[-1] =~ /^[\?\*\+]$/) {
            my $quant = pop @$next;
            return $self->match_times($quant, $method => $next);
        }
        else {
            return $self->$method($next);
        }
    }
    else {
        $method = ($next =~ s/^=//) ? 'match_token' : 'match_ref';
        if ($next =~ s/([\?\*\+])$//) {
            return $self->match_times($1, $method => $next);
        }
        else {
            return $self->$method($next);
        }
    }
}

sub match_times {
    my ($self, $quantity, $method, @args) = @_;
    my ($min, $max) =
        $quantity eq '' ? (1, 1) :
        $quantity eq '?' ? (0, 1) :
        $quantity eq '*' ? (0, 0) :
        $quantity eq '+' ? (1, 0) : die "Bad quantity '$quantity'";
    my $stop = $max || 9999;
    my $count = 0;
    my $pointer = $self->{pointer};
    while ($stop-- and $self->$method(@args)) {
        $count++;
    }
    return 1 if $count >= $min and (not $max or $count <= $max);
    $self->{pointer} = $pointer;
    return;
}

sub match_any {
    my ($self, $any) = @_;
    my $pointer = $self->{pointer};
    for (@$any) {
        if ($self->match_next($_)) {
            return 1;
        }
    }
    $self->{pointer} = $pointer;
    return;
}

sub match_all {
    my ($self, $all) = @_;
    my $pointer = $self->{pointer};
    for (@$all) {
        if (not $self->match_next($_)) {
            $self->{pointer} = $pointer;
            return;
        }
    }
    return 1;
}

sub match_ref {
    my ($self, $ref) = @_;
    my $rule = $self->{grammar}->{$ref}
        or Carp::confess "Not a rule reference: '$ref'";
    $self->match_next($rule);
}

sub match_token {
    my ($self, $token_want) = @_;
    my $not = ($token_want =~ s/^\!//) ? 1 : 0;
    return if $self->{pointer} >= @{$self->{tokens}};
    my $token = $self->{tokens}[$self->{pointer}];
    my $token_got = $token->[0];
    if (($token_want eq $token_got) xor $not) {
        $token_got =~ s/-/_/g;
        my $method = "got_$token_got";
        if ($self->can($method)) {
            # say $method;
            $self->$method($token);
        }
        $self->{pointer}++;
        return 1;
    }
    return;
}

#------------------------------------------------------------------------------
# Receiver/ast-generator methods:
#------------------------------------------------------------------------------
sub got_directive_start {
    my ($self, $token) = @_;
    $self->{directive_name} = $token->[1];
}

sub got_directive_value {
    my ($self, $token) = @_;
    my $value = $token->[1];
    $value =~ s/\s+$//;
    my $name = $self->{directive_name};
    if (my $old_value = $self->{tree}{"+$name"}) {
        if (not ref($old_value)) {
            $old_value = $self->{tree}{"+$name"} = [$old_value];
        }
        push @$old_value, $value;
    }
    else {
        $self->{tree}{"+$name"} = $value;
    }
}

sub got_rule_start {
    my ($self, $token) = @_;
    $self->{stack} = [];
    my $rule_name = $token->[1];
    $rule_name =~ s/-/_/g;
    $self->{rule_name} = $rule_name;
    $self->{tree}{'+toprule'} ||= $rule_name;
    $self->{groups} = [[0, ':']];
}

sub got_rule_end {
    my ($self) = @_;
    $self->{tree}{$self->{rule_name}} = $self->group_ast;
}

sub got_group_start {
    my ($self, $token) = @_;
    my $gmod = $token->[1];
    push @{$self->{groups}}, [scalar(@{$self->{stack}}), $token->[1]];
}

sub got_group_end {
    my ($self, $token) = @_;
    my $rule = $self->group_ast;
    $self->set_quantity($token->[1], $rule);
    push @{$self->{stack}}, $rule;
}

sub got_list_alt {
    my ($self) = @_;
    push @{$self->{stack}}, '|';
}

sub got_list_sep {
    my ($self, $token) = @_;
    push @{$self->{stack}}, $token->[1];
}

sub got_rule_reference {
    my ($self, $token) = @_;
    my $name = $token->[2];
    $name =~ s/-/_/g;
    $name =~ s/^<(.*)>$/$1/;
    my $rule = { '.ref' => $name };
    $self->set_modifier($token->[1], $rule);
    $self->set_quantity($token->[3], $rule);
    push @{$self->{stack}}, $rule;
}

sub got_error_message {
    my ($self, $token) = @_;
    push @{$self->{stack}}, { '.err' => $token->[1] };
}

sub got_whitespace_maybe {
    my ($self) = @_;
    $self->got_rule_reference(['whitespace-maybe', undef, '_', undef]);
}

sub got_whitespace_must {
    my ($self) = @_;
    $self->got_rule_reference(['whitespace-maybe', undef, '__', undef]);
}

sub got_regex_start {
    my ($self) = @_;
    push @{$self->{groups}}, [scalar(@{$self->{stack}}), '/'];
}

sub got_regex_end {
    my ($self) = @_;
    my $regex = join '', map {
        if (ref($_)) {
            my $part = $_->{'.ref'};
            "<$part>";
        }
        else {
            $_;
        }
    } splice(@{$self->{stack}}, (pop $self->{groups})->[0]);
    push @{$self->{stack}}, {'.rgx' => $regex};
}

sub got_regex_raw {
    my ($self, $token) = @_;
    push @{$self->{stack}}, $token->[1];
}

#------------------------------------------------------------------------------
# Receiver helper methods:
#------------------------------------------------------------------------------
sub group_ast {
    my ($self) = @_;
    my ($offset, $gmod) = @{pop $self->{groups}};
    $gmod ||= '';
    my $rule = [splice(@{$self->{stack}}, $offset)];

    for (my $i = 0; $i < @$rule-1; $i++) {
        if ($rule->[$i + 1] =~ /^%%?$/) {
            my $sep = splice @$rule, $i+1, 1;
            $rule->[$i]->{'.sep'} = splice @$rule, $i+1, 1;
            $rule->[$i]->{'.sep'}{'+eok'} = 1 if $sep eq '%%';
        }
    }
    my $started = 0;
    for (
        my $i = (@$rule and $rule->[0] eq '|') ? 1 : 0;
        $i < @$rule-1;
        $i++
    ) {
        next if $rule->[$i] eq '|';
        if ($rule->[$i+1] eq '|') {
            $i++;
            $started = 0;
        }
        else {
            $rule->[$i] = {'.all' => [$rule->[$i]]}
                unless $started++;
            push @{$rule->[$i]{'.all'}}, splice @$rule, $i+1, 1;
            $i--
        }
    }
    if (grep {$_ eq '|'} @$rule) {
        $rule = [{'.any' => [ grep {$_ ne '|'} @$rule ]}];
    }

    $rule = $rule->[0] if @$rule <= 1;
    $rule->{'-skip'} = 1 if $gmod eq '.';

    return $rule;
}

sub set_quantity {
    my ($self, $quantity, $rule) = @_;
    if ($quantity) {
        if ($quantity eq '?') {
            $rule->{'+max'} = 1;
        }
        elsif ($quantity eq '*') {
            $rule->{'+min'} = 0;
        }
        elsif ($quantity eq '+') {
            $rule->{'+min'} = 1;
        }
        elsif ($quantity =~ /^(\d+)$/) {
            $rule->{'+min'} = $1;
            $rule->{'+max'} = $1;
        }
        elsif ($quantity =~ /^(\d+)-(\d+)$/) {
            $rule->{'+min'} = $1;
            $rule->{'+max'} = $2;
        }
        elsif ($quantity =~ /^(\d+)\+$/) {
            $rule->{'+min'} = $1;
        }
    }
}

sub set_modifier {
    my ($self, $modifier, $rule) = @_;
    if ($modifier) {
        if ($modifier eq '=') {
            $rule->{'+asr'} = 1;
        }
        elsif ($modifier eq '!') {
            $rule->{'+asr'} = -1;
        }
        elsif ($modifier eq '.') {
            $rule->{'-skip'} = 1;
        }
        elsif ($modifier eq '+') {
            $rule->{'-wrap'} = 1;
        }
        elsif ($modifier eq '-') {
            $rule->{'-pass'} = 1;
        }
    }
}

# DEBUG: wrap/trace parse methods:
# for my $method (qw(
#     match_times match_next match_ref match_token match_any match_all
# )) {
#     no strict 'refs';
#     no warnings 'redefine';
#     my $orig = \&$method;
#     *$method = sub {
#         my $self = shift;
#         my $args = join ', ', map {
#             ref($_) ? '[' . join(', ', @$_) . ']' :
#             length($_) ? $_ : "''"
#         } @_;
#         say "$method($args)";
#         die if $main::x++ > 250;
#         $orig->($self, @_);
#     };
# }

#------------------------------------------------------------------------------
# Lexer logic:
#------------------------------------------------------------------------------
my $ALPHA = 'A-Za-z';
my $DIGIT = '0-9';
my $DASH  = '\-';
my $SEMI  = '\;';
my $UNDER  = '\_';
my $HASH  = '\#';
my $EOL   = '\n';
my $WORD  = "$DASH$UNDER$ALPHA$DIGIT";
my $SPACE = "(?:[\ \t]|$HASH.*$EOL)";
my $MOD   = '[\!\=\-\+\.]';
my $GMOD  = '[\.]';
my $QUANT = '(?:[\?\*\+]|\d+(?:\+|\-\d+)?)';
my $NAME  = "[$UNDER$ALPHA](?:[$WORD]*[$ALPHA$DIGIT])?";
my $REM   = "(?:$SPACE+|$EOL+)";
has regexes => {
    pegex => [
        [qr/\A%(grammar|version|extends|include)$SPACE+/,
            'directive-start', 'directive'],

        [qr/\A($NAME)(?=$SPACE*\:)/,
            'rule-start', 'rule'],

        [qr/\A$REM/],

        [qr/\A\z/,
            'pegex-end', 'end'],
    ],
    rule => [
        [qr/\A\:/,
            'rule-sep'],

        [qr/\A(?:\+|\~\~|\-\-)(?=\s)/,
            'whitespace-must'],
        [qr/\A(?:\-|\~)(?=\s)/,
            'whitespace-maybe'],

        [qr/\A($MOD)?($NAME|<$NAME>)($QUANT)?/,
            'rule-reference'],
        [qr/\A\//,
            'regex-start', 'regex'],
        [qr/\A\`([^\`\n]*?)\`/,
            'error-message'],

        [qr/\A($GMOD)?\(/,
            'group-start'],
        [qr/\A\)($QUANT)?/,
            'group-end'],
        [qr/\A\|/,
            'list-alt'],
        [qr/\A(\%\%?)/,
            'list-sep'],

        [qr/\A(?:$SEMI$SPACE*$EOL?|\s*$EOL)(?=$NAME$SPACE*\:|\z)/,
            'rule-end', 'end'],

        [qr/\A$REM/],
    ],
    directive => [
        [qr/\A(\S.*)/,
            'directive-value'],
        [qr/\A$EOL/,
            'directive-end', 'end']
    ],
    regex => [
        [qr/\A(?:\+|\~\~|\-\-)(?=[\s\/])/,
            'whitespace-must'],
        [qr/\A(?:\-|~)(?=[\s\/])/,
            'whitespace-maybe'],
        [qr/\A([^\s\/]+)/,
            'regex-raw'],
        [qr/\A$SPACE+/],
        [qr/\A$EOL+/],
        [qr/\A\//,
            'regex-end', 'end'],
        [qr/\A$REM/],
    ],
};

sub lex {
    my ($self, $grammar) = @_;

    my $tokens = $self->{tokens} = [['pegex-start']];
    my $stack = ['pegex'];
    my $pos = 0;

    OUTER: while (1) {
        my $state = $stack->[-1];
        my $set = $self->{regexes}->{$state} or die "Invalid state '$state'";
        for my $entry (@$set) {
            my ($regex, $name, $scope) = @$entry;
            if (substr($grammar, $pos) =~ $regex) {
                $pos += length($&);
                if ($name) {
                    no strict 'refs';
                    my @captures = map $$_, 1..$#+;
                    pop @captures
                        while @captures and not defined $captures[-1];
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
}

1;

# vim: set lisp:
