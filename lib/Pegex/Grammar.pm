package Pegex::Grammar;
use strict;
use warnings;
use 5.008003;
use Pegex::Base -base;

has 'grammar';
has 'grammar_text';
has 'grammar_tree';
has 'receiver' => -init => 'require Pegex::AST; Pegex::AST->new()';

has 'input';
has 'position';
has 'match_groups';

sub parse {
    my $self = shift;
    die 'Pegex::Grammar->parse() takes one or two arguments ($input, $start_rule)'
        unless @_ >= 1 and @_ <= 2;
    $self->input(shift);
    $self->position(0);
    $self->match_groups([]);
    my $start_rule = shift || undef;

    if (not $self->grammar) {
        my $grammar_tree = $self->grammar_tree;
        if (not $grammar_tree) {
            my $grammar_text = $self->grammar_text;
            if (not $grammar_text) {
                die ref($self) . " object has no grammar";
            }
            require Pegex::Compiler;
            $grammar_tree = Pegex::Compiler->new->compile($grammar_text)->grammar;
        }
        $self->grammar($grammar_tree);
    }

    if (not ref $self->receiver) {
        $self->receiver($self->receiver->new);
    }

    $start_rule ||= 
        $self->grammar->{TOP}
            ? 'TOP'
            : $self->grammar->{_FIRST_RULE};

    $self->action("__begin__");
    $self->match($start_rule);
    if ($self->position < length($self->input)) {
        $self->throw_error("Parse document failed for some reason");
    }
    $self->action("__end__");

    if ($self->receiver->can('data')) {
        return $self->receiver->data;
    }
    else {
        return 1;
    }
}

sub match {
    my $self = shift;
    my $rule = shift or die "No rule passed to match";

    my $not = 0;

    my $state = undef;
    if (not ref($rule) and $rule =~ /^\w+$/) {
        die "\n\n*** No grammar support for '$rule'\n\n"
            unless $self->grammar->{$rule};
        $state = $rule;
        $rule = $self->grammar->{$rule}
    }

    my $kind;
    my $times = $rule->{'<'} || '1';
    if ($rule->{'+not'}) {
        $rule = $rule->{'+not'};
        $kind = 'rule';
        $not = 1;
    }
    elsif ($rule->{'+rule'}) {
        $rule = $rule->{'+rule'};
        $kind = 'rule';
    }
    elsif (defined $rule->{'+re'}) {
        $rule = $rule->{'+re'};
        $kind = 'regexp';
    }
    elsif ($rule->{'+all'}) {
        $rule = $rule->{'+all'};
        $kind = 'all';
    }
    elsif ($rule->{'+any'}) {
        $rule = $rule->{'+any'};
        $kind = 'any';
    }
    elsif ($rule->{'+error'}) {
        my $error = $rule->{'+error'};
        $self->throw_error($error);
    }
    else {
        require Carp;
        Carp::confess("no support for $rule");
    }

    if ($state and not $not) {
        $self->callback("try_$state");
        $self->action("__try__", $state, $kind);
    }

    my $position = $self->position;
    my $count = 0;
    my $method = ($kind eq 'rule') ? 'match' : "match_$kind";
    while ($self->$method($rule)) {
        $count++;
        last if $times eq '1' or $times eq '?';
    }
    my $result = (($count or $times eq '?' or $times eq '*') ? 1 : 0) ^ $not;

    if ($state and not $not) {
        $result
            ? $self->action("__got__", $state, $method)
            : $self->callback("__not__", $state, $method);
        $result
            ? $self->callback("got_$state")
            : $self->callback("not_$state");
        $self->callback("end_$state")
    }

    $self->position($position) unless $result;
    return $result;
}

sub match_all {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) or return 0;
    }
    return 1;
}

sub match_any {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) and return 1;
    }
    return 0;
}

sub match_regexp {
    my $self = shift;
    my $regexp = shift;

    pos($self->{input}) = $self->position;
    $self->{input} =~ /$regexp/g or return 0;
    if (defined $1) {
        $self->match_groups([
            grep defined($_), ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ]);
    }
    $self->position(pos($self->{input}));

    return 1;
}

sub action {
    my $self = shift;
    my $method = shift;

    if ($self->receiver->can($method)) {
        $self->receiver->$method(@_, $self->match_groups);
    }
}

sub callback {
    my $self = shift;
    my $method = shift;

    if ($self->receiver->can($method)) {
        $self->receiver->$method(@{$self->match_groups});
    }
}

sub throw_error {
    my $self = shift;
    my $msg = shift;
    die $msg;
#     my $line = @{[substr($self->input, 0, $self->position) =~ /(\n)/g]} + 1;
#     my $context = substr($self->input, $self->position, 50);
#     $context =~ s/\n/\\n/g;
#     die <<"...";
# Error parsing TestML document:
#   msg: $msg
#   line: $line
#   context: "$context"
# ...
}

1;
