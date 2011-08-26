##
# name:      Pegex::Grammar
# abstract:  Pegex Grammar Runtime
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Grammar;
use strict;
use warnings;
use 5.008003;
use Pegex::Base -base;

has 'tree' => -init => '$self->build_tree';
has 'build_tree' => {};
has 'receiver' => -init => 'require Pegex::AST; Pegex::AST->new()';
has 'debug' => 0;

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

    die ref($self) . " has no grammar 'tree' property"
        if not $self->tree;

    if (not $self->receiver) {
        $self->receiver('Pegex::Return');
    }
    if (not ref $self->receiver) {
        my $receiver = $self->receiver;
        eval "require $receiver";
        $self->receiver($receiver->new);
    }

    $start_rule ||= 
        $self->tree->{TOP}
            ? 'TOP'
            : $self->tree->{_FIRST_RULE};

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

    my $state = undef;
    if (not ref($rule) and $rule =~ /^\w+$/) {
        die "\n\n*** No grammar support for '$rule'\n\n"
            unless $self->tree->{$rule};
        $state = $rule;
        $rule = $self->tree->{$rule};
    }

    my $kind;
    my $times = '1';
    my $not = 0;
    my $has = 0;
    if (my $mod = $rule->{'<'}) {
        if ($mod eq '!') {
            $not = 1;
        }
        elsif ($mod eq '=') {
            $has = 1;
        }
        else {
            $times = $mod;
        }
    }
    if ($rule->{'+rule'}) {
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
        $self->trace("try_$state", 1);
        $self->callback("try_$state");
        $self->action("__try__", $state, $kind);
    }

    my $position = $self->position;
    my $count = 0;
    my $method = ($kind eq 'rule') ? 'match' : "match_$kind";
    while ($self->$method($rule)) {
        $position = $self->position unless $not;
        $count++;
        last if $times eq '1' or $times eq '?';
    }
    if ($count and $times =~ /[\+\*]/) {
        $self->position($position);
    }
    my $result = (($count or $times =~ /^[\?\*]$/) ? 1 : 0) ^ $not;
    $self->position($position) unless $result;

    if ($state and not $not) {
        $self->trace(($result ? "got" : "not") . "_$state");

        $result
            ? $self->action("__got__", $state, $method)
            : $self->action("__not__", $state, $method);
        $result
            ? $self->callback("got_$state")
            : $self->callback("not_$state");
# XXX doesn't seem to be used.
#         $self->callback("end_$state");
    }
    return $result;
}

sub trace {
    my $self = shift;
    return unless $self->debug;
    my $action = shift;
    my $indent = shift || 0;
    $self->{indent} ||= 0;
    $self->{indent}-- unless $indent;
    print ' ' x $self->{indent};
    $self->{indent}++ if $indent;
    my $snippet = substr($self->input, $self->position);
    $snippet = substr($snippet, 0, 30) . "..." if length $snippet > 30;
    $snippet =~ s/\n/\\n/g;
    print sprintf("%-30s", $action) . ($indent ? " >$snippet<\n" : "\n");
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
    {
        no strict 'refs';
        $self->match_groups([ map ${$_}, 1..$#+ ]);
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
#     die $msg;
    my $line = @{[substr($self->input, 0, $self->position) =~ /(\n)/g]} + 1;
    my $context = substr($self->input, $self->position, 50);
    $context =~ s/\n/\\n/g;
    my $position = $self->position;
    die <<"...";
Error parsing Pegex document:
  msg: $msg
  line: $line
  context: "$context"
  position: $position
...
}

1;

=head1 SYNOPSIS

    my $grammar = Pegex::Grammar::Subclass->new(
        receiver => Pegex::Receiver::Subclass->new,
    );

    my $data = $grammar->parse($input_text);

=head1 DESCRIPTION

Pegex::Grammar is the runtime engine for all the grammar modules that subclass
it.

The subclass provides a compiled grammar tree, via the C<tree> method.

The C<parse> method applies the grammar against the text, and tells the
receiver object what is happening as it happens. If the parse fails, an error
is thrown. If it succeeds, then C<parse> returns the C<data> property of the
C<receiver> object.
