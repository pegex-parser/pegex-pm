##
# name:      Pegex::Parser::Bootstrap
# abstract:  Pegex Parser Runtime Bootstrap for TestML
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Pegex::Grammar

package Pegex::Parser::Bootstrap;
use Pegex::Base;

use Pegex::Input;

# Parser and receiver objects/classes to use.
has 'grammar';
has 'receiver' => default => sub {
    require Pegex::AST::Bootstrap;
    Pegex::AST::Bootstrap->new();
};

# Internal properties.
has 'input';
has 'buffer';
has 'position' => default => sub{0};
has 'match_groups' => default => sub{[]};

# Debug the parsing of input.
has 'debug' => builder => 'debug_';
sub debug_ {
    exists($ENV{PERL_PEGEX_DEBUG}) ? $ENV{PERL_PEGEX_DEBUG} :
    defined($Pegex::Parser::Debug) ? $Pegex::Parser::Debug :
    0;
}

sub parse {
    my $self = shift;
    $self = $self->new unless ref $self;

    die "Usage: " . ref($self) . '->parse($input [, $start_rule]'
        unless 1 <= @_ and @_ <= 2;

    my $input = (ref $_[0] and UNIVERSAL::isa($_[0], 'Pegex::Input'))
        ? shift
        : Pegex::Input->new(shift)->open;
    $self->input($input);

    $self->buffer($self->input->read);

    my $start_rule = shift || undef;
    $start_rule ||= 
        $self->grammar->tree->{TOP}
            ? 'TOP'
            : $self->grammar->tree->{'+top'}
        or die "No starting rule for Pegex::Parser::parse";

    my $receiver = $self->receiver or die "No 'receiver'. Can't parse";
    if (not ref $receiver) {
        eval "require $receiver";
        $self->receiver($receiver->new);
    }

    $self->match($start_rule);

    # Parse was successful!
    $self->input->close;
    return ($self->receiver->can('data') ? $self->receiver->data : 1);
}

sub match {
    my ($self, $rule) = @_;

    $self->receiver->__begin__()
        if $self->receiver->can("__begin__");

    $self->match_ref($rule);
    if ($self->position < length($self->buffer)) {
        $self->throw_error("Parse document failed for some reason");
    }

    $self->receiver->__final__()
        if $self->receiver->can("__final__");
}

sub match_next {
    my ($self, $next, $state) = @_;

    my ($has, $not, $times) = (0, 0, '1');
    if (my $mod = $next->{'+mod'}) {
        ($mod eq '=') ? ($has = 1) :
        ($mod eq '!') ? ($not = 1) :
        ($times = $mod);
    }

    my ($rule, $kind) = map {($next->{".$_"}, $_)}
        grep {$next->{".$_"}} qw(ref rgx all any err)
            or XXX $next;

    $self->callback("try", $state, $kind)
        if $state and not $not;

    my $position = $self->position;
    my $count = 0;
    my $method = "match_$kind";
    while ($self->$method($rule)) {
        $position = $self->position unless $not;
        $count++;
        last if $times =~ /^[1?]$/;
    }
    $self->position($position) if $count and $times =~ /^[+*]$/;
    my $result = (($count or $times =~ /^[?*]$/) ? 1 : 0) ^ $not;
    $self->position($position) unless $result;

    $self->callback(($result ? "got" : "not"), $state, $kind)
        if $state and not $not;

    return $result;
}

sub match_ref {
    my ($self, $rule) = @_;
    die "\n\n*** No grammar support for '$rule'\n\n"
        unless $self->grammar->tree->{$rule};
    $self->match_next($self->grammar->tree->{$rule}, $rule);
}

sub match_all {
    my $self = shift;
    my $list = shift;
    my $pos = $self->position;
    for my $elem (@$list) {
        $self->match_next($elem) or $self->position($pos) and return 0;
    }
    return 1;
}

sub match_any {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match_next($elem) and return 1;
    }
    return 0;
}

sub match_rgx {
    my $self = shift;
    my $regexp = shift;

    pos($self->{buffer}) = $self->position;
    $self->{buffer} =~ /$regexp/g or return 0;
    {
        no strict 'refs';
        $self->match_groups([ map $$_, 1..$#+ ]);
    }
    $self->position(pos($self->{buffer}));

    return 1;
}

sub match_err {
    my ($self, $error) = @_;
    $self->throw_error($error);
}

sub callback {
    my ($self, $adj, $state) = @_;
    my $callback = "${adj}_$state";
    my $got = $adj eq 'got';

    $self->trace($callback) if $self->debug;

    my $done = 0;
    if ($self->receiver->can($callback)) {
        $self->receiver->$callback(@{$self->match_groups});
        $done++;
    }
    $callback = "end_$state";
    if ($adj =~ /ot$/ and $self->receiver->can($callback)) {
        $self->receiver->$callback($got, @{$self->match_groups});
        $done++
    }
    return if $done;

    $callback = "__${adj}__";
    if ($self->receiver->can($callback)) {
        $self->receiver->$callback($state, $self->match_groups);
    }
    $callback = "__end__";
    if ($adj =~ /ot$/ and $self->receiver->can($callback)) {
        $self->receiver->$callback($got, $state, $self->match_groups);
    }
}

sub trace {
    my $self = shift;
    my $action = shift;
    my $indent = ($action =~ /^try_/) ? 1 : 0;
    $self->{indent} ||= 0;
    $self->{indent}-- unless $indent;
    print ' ' x $self->{indent};
    $self->{indent}++ if $indent;
    my $snippet = substr($self->buffer, $self->position);
    $snippet = substr($snippet, 0, 30) . "..." if length $snippet > 30;
    $snippet =~ s/\n/\\n/g;
    print sprintf("%-30s", $action) . ($indent ? " >$snippet<\n" : "\n");
}

sub throw_error {
    my $self = shift;
    my $msg = shift;
    my $line = @{[substr($self->buffer, 0, $self->position) =~ /(\n)/g]} + 1;
    my $context = substr($self->buffer, $self->position, 50);
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
