##
# name:      Pegex::Parser
# abstract:  Pegex Parser Runtime
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Pegex::Grammar

package Pegex::Parser2;
use Pegex::Base -base;

use Pegex::Input;

# Parser and receiver objects/classes to use.
has 'grammar';
has 'receiver' => -init => 'require Pegex::AST; Pegex::AST->new()';

# Internal properties.
has 'input';
has 'buffer';
has 'position' => 0;
has 'match_groups' => [];

# Debug the parsing of input.
has 'debug' => -init => '$self->debug_';
sub debug_ {
    exists($ENV{PERL_PEGEX_DEBUG}) ? $ENV{PERL_PEGEX_DEBUG} :
    defined($Pegex::Parser::Debug) ? $Pegex::Parser::Debug :
    0;
}

my $ignore = bless {}, 'IGNORE ME';

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

    my $match = $self->match_ref($rule);
    $self->throw_error("Parse document failed for some reason")
        if $self->position < length($self->buffer);

    $self->receiver->__final__($match)
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

    my $match = [];
    $match = $self->callback("try", $kind, $state, $match)
        if $state and not $not;
    $match ||= $ignore;

    my ($position, $count, $method) =
        ($self->position, 0, "match_$kind");
    while (my $return = $self->$method($rule)) {
        $position = $self->position unless $not;
        $count++;
        if ($times =~ /^[1?]$/) {
            $match = $return;
            last;
        }
        push @$match, $return unless $return eq $ignore;
    }
    $self->position($position) if $count and $times =~ /^[+*]$/;
    my $result = (($count or $times =~ /^[?*]$/) ? 1 : 0) ^ $not;
    $self->position($position) unless $result;

    $match = $self->callback(($result ? "got" : "not"), $kind, $state, $match)
        if $state and not $not;
    $match ||= $ignore;

    return ($result ? $match : 0);
}

sub match_ref {
    my ($self, $rule) = @_;
    die "\n\n*** No grammar support for '$rule'\n\n"
        unless $self->grammar->tree->{$rule};
    return $self->match_next($self->grammar->tree->{$rule}, $rule);
}

sub match_all {
    my ($self, $list) = @_;
    my $pos = $self->position;
    my $set = [];
    for my $elem (@$list) {
        if (my $match = $self->match_next($elem)) {
            push @$set, $match unless $match eq $ignore;
        }
        else {
            $self->position($pos);
            return 0;
        }
    }
    return $set;
}

sub match_any {
    my ($self, $list) = @_;
    for my $elem (@$list) {
        if (my $match = $self->match_next($elem)) {
            return $match;
        }
    }
    return 0;
}

sub match_rgx {
    my ($self, $regexp) = @_;

    pos($self->{buffer}) = $self->position;
    $self->{buffer} =~ /$regexp/g or return 0;
    my $match;
    {
        no strict 'refs';
        $match = [ map $$_, 1..$#+ ];
    }
    $self->position(pos($self->{buffer}));

    return $match;
}

sub match_err {
    my ($self, $error) = @_;
    $self->throw_error($error);
}

sub callback {
    my ($self, $adj, $kind, $rule, $match) = @_;
    my $callback = "${adj}_$rule";
    my $got = $adj eq 'got';

    $self->trace($callback) if $self->debug;

    my $done = 0;
    if ($self->receiver->can($callback)) {
        $self->receiver->$callback(@{$self->match_groups});
        $done++;
    }
    $callback = "end_$rule";
    if ($adj =~ /ot$/ and $self->receiver->can($callback)) {
        $self->receiver->$callback($got, @{$self->match_groups});
        $done++
    }
    return $match if $done;

    $callback = "__${adj}__";
    if ($self->receiver->can($callback)) {
        $match = $self->receiver->$callback($kind, $rule, $match);
    }
    $callback = "__end__";
    if ($adj =~ /ot$/ and $self->receiver->can($callback)) {
        $match = $self->receiver->$callback($got, $kind, $rule, $match);
    }
    return $match;
}

sub trace {
    my $self = shift;
    my $action = shift;
    my $indent = ($action =~ /^try_/) ? 1 : 0;
    $self->{indent} ||= 0;
    $self->{indent}-- unless $indent;
    print STDERR ' ' x $self->{indent};
    $self->{indent}++ if $indent;
    my $snippet = substr($self->buffer, $self->position);
    $snippet = substr($snippet, 0, 30) . "..." if length $snippet > 30;
    $snippet =~ s/\n/\\n/g;
    print STDERR sprintf("%-30s", $action) . ($indent ? " >$snippet<\n" : "\n");
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

=head1 SYNOPSIS

    use Pegex::Parser;

=head1 DESCRIPTION

This is the Pegex module that provides the parsing engine runtime. It has a
C<parse()> method that applies a grammar to a text that supposedly matches
that grammar. It also calls the callback methods of its Receiver object.

Generally this module is not used directly, but is called upon via a
L<Pegex::Grammar> object.
