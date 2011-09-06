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

use Scalar::Util;

# Parser and receiver objects/classes to use.
has 'grammar';
has 'receiver' => -init => 'require Pegex::AST; Pegex::AST->new()';

# Internal properties.
has 'input';
has 'buffer';
has 'position' => 0;
has 'match_groups' => [];
has 'error' => 'die';

# Debug the parsing of input.
has 'debug' => -init => '$self->debug_';

sub debug_ {
    exists($ENV{PERL_PEGEX_DEBUG}) ? $ENV{PERL_PEGEX_DEBUG} :
    defined($Pegex::Parser::Debug) ? $Pegex::Parser::Debug :
    0;
}

$Pegex::Ignore = bless {}, 'Pegex-Ignore';

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

    my $grammar = $self->grammar or die "No 'grammar'. Can't parse";
    if (not ref $grammar) {
        eval "require $grammar";
        $self->grammar($grammar->new);
    }

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
    # Add circular ref and weaken it.
    $self->receiver->parser($self);
    Scalar::Util::weaken($self->receiver->{parser});

    my $match = $self->match($start_rule) or return;

    # Parse was successful!
    $self->input->close;
    return ($self->receiver->data || $match);
}

sub match {
    my ($self, $rule) = @_;

    $self->receiver->begin()
        if $self->receiver->can("begin");

    my $match = $self->match_ref($rule);
    if ($self->position < length($self->buffer)) {
        $self->throw_error("Parse document failed for some reason");
        return;  # If $self->error eq 'live'
    }

    $match = $self->receiver->final($match, $rule)
        if $self->receiver->can("final");

    return $match;
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

    $self->callback("try", $state) if $state and not($has or $not);

    my ($match, $position, $count, $method) =
        ([], $self->position, 0, "match_$kind");
    while (my $return = $self->$method($rule)) {
        $position = $self->position unless $not;
        $count++;
        if ($times =~ /^[1?]$/) {
            $match = $return;
            last;
        }
        push @$match, $return unless $return eq $Pegex::Ignore;
    }
    $self->position($position) if $count and $times =~ /^[+*]$/;
    my $result = (($count or $times =~ /^[?*]$/) ? 1 : 0) ^ $not;
    $self->position($position) unless $result;

    $match = $self->callback(($result ? "got" : "not"), $state, $match)
        if $state and not($has or $not);
    $match ||= $Pegex::Ignore;

    return ($result ? $match : 0);
}

sub match_ref {
    my ($self, $rule) = @_;
    die "\n\n*** No grammar support for '$rule'\n\n"
        unless $self->grammar->tree->{$rule};
    return $self->match_next($self->grammar->tree->{$rule}, $rule);
}

sub match_rgx {
    my ($self, $regexp) = @_;

    my $start = pos($self->{buffer}) = $self->position;
    $self->{buffer} =~ /$regexp/g or return 0;
    my $finish = pos($self->{buffer});
    no strict 'refs';
    my $match = +{ map {($_, $$_)} 1..$#+ };

    $self->position($finish);

    return $match;
}

sub match_all {
    my ($self, $list) = @_;
    my $pos = $self->position;
    my $set = [];
    for my $elem (@$list) {
        if (my $match = $self->match_next($elem)) {
            push @$set, $match unless $match eq $Pegex::Ignore;
        }
        else {
            $self->position($pos);
            return 0;
        }
    }
    return $set->[0] if @$list == 1;
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

sub match_err {
    my ($self, $error) = @_;
    $self->throw_error($error);
}

sub callback {
    my ($self, $adj, $rule, $match) = @_;
    my $callback = "${adj}_$rule";
    $self->trace($callback) if $self->debug;
    return unless $adj eq 'got';
    $match = $self->receiver->got($rule, $match)
        if $self->receiver->can("got");
    $match = $self->receiver->$callback($match)
        if $self->receiver->can($callback);
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
    my $error = <<"...";
Error parsing Pegex document:
  msg: $msg
  line: $line
  context: "$context"
  position: $position
...
    if ($self->error eq 'die') {
        require Carp;
        Carp::croak($error);
    }
    elsif ($self->error eq 'live') {
        $@ = $error;
        return;
    }
    else {
        die "Invalid value for Pegex::Parser::error";
    }
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
