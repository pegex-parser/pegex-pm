#u
# name:      Pegex::Parser
# abstract:  Pegex Parser Runtime
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Pegex::Grammar

package Pegex::Parser;
use Pegex::Mo;

use Pegex::Input;

use Scalar::Util;

# Grammar object or class
has 'grammar';
# Receiver object or class
has 'receiver' => default => sub {
    require Pegex::Receiver;
    Pegex::Receiver->new();
};

# Parser options
has 'throw_on_error' => default => sub {1};
# Allow a partial parse
has 'partial' => default => sub {0};

# Internal properties.
has 'input';
has 'buffer';
has 'position' => default => sub {0};

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

    my $grammar = $self->grammar or die "No 'grammar'. Can't parse";
    if (not ref $grammar) {
        eval "require $grammar";
        $self->grammar($grammar->new);
    }

    my $start_rule = shift ||
        $self->grammar->tree->{'+top'} ||
        ($self->grammar->tree->{'TOP'} ? 'TOP' : undef)
            or die "No starting rule for Pegex::Parser::parse";

    my $receiver = $self->receiver or die "No 'receiver'. Can't parse";
    if (not ref $receiver) {
        eval "require $receiver";
        $self->receiver($receiver->new);
    }
    # Add circular ref and weaken it.
    $self->receiver->parser($self);
    Scalar::Util::weaken($self->receiver->{parser});

    # Do the parse
    my $match = $self->match($start_rule) or return;

    # Parse was successful!
    $self->input->close;
    return ($self->receiver->data || $match);
}

sub match {
    my ($self, $rule) = @_;

    $self->receiver->initialize($rule)
        if $self->receiver->can("initialize");

    my $match = $self->match_next({'.ref' => $rule});
    if (not $match or $self->position < length($self->buffer)) {
        $self->throw_error("Parse document failed for some reason");
        return;  # In case $self->throw_on_error is off
    }
    $match = $match->[0];

    $match = $self->receiver->finalize($match, $rule)
        if $self->receiver->can("finalize");

    $match = {$rule => []} unless $match;

    $match = $match->{TOP} || $match if $rule eq 'TOP';

    return $match;
}

sub match_next {
    my ($self, $next) = @_;

    return $self->match_next_with_sep($next)
        if $next->{'.sep'};

    my $quantity = $next->{'+qty'} || '1';
    my $assertion = $next->{'+asr'} || 0;
    my ($rule, $kind) = map {($next->{".$_"}, $_)}
        grep {$next->{".$_"}} qw(ref rgx all any err) or XXX $next;

    my ($match, $position, $count, $method) =
        ([], $self->position, 0, "match_$kind");
    while (my $return = $self->$method($rule, $next)) {
        $position = $self->position unless $assertion;
        $count++;
        push @$match, @$return;
        last if $quantity =~ /^[1?]$/;
    }
    if ($quantity =~ /^[+*]$/) {
        $match = [$match]; # if $count;
        $self->position($position);
    }
    my $result = (($count or $quantity =~ /^[?*]$/) ? 1 : 0)
        ^ ($assertion == -1);
    $self->position($position)
        if not($result) or $assertion;

    $match = [] if $next->{'-skip'};
    return ($result ? $match : 0);
}

sub match_next_with_sep {
    my ($self, $next) = @_;

    my $quantity = $next->{'+qty'} || '1';
    my ($rule, $kind) = map {($next->{".$_"}, $_)}
        grep {$next->{".$_"}} qw(ref rgx all any err) or XXX $next;

    my $separator = $next->{'.sep'};
    my ($sep_rule, $sep_kind) = map {($separator->{".$_"}, $_)}
        grep {$separator->{".$_"}} qw(ref rgx all any err) or XXX $separator;

    my ($match, $position, $count, $sep_count, $method, $sep_method) =
        ([], $self->position, 0, 0, "match_$kind", "match_$sep_kind");
    while (my $return = $self->$method($rule, $next)) {
        $position = $self->position;
        $count++;
        push @$match, @$return;
        $return = $self->$sep_method($sep_rule, $separator) or last;
        push @$match, @$return;
        $sep_count++;
    }
    return ($quantity eq '?') ? [$match] : 0 unless $count;
    $self->position($position) if $count == $sep_count;

    return [] if $next->{'-skip'};
    return [$match];
}

sub match_ref {
    my ($self, $ref, $parent) = @_;
    my $rule = $self->grammar->tree->{$ref}
        or die "\n\n*** No grammar support for '$ref'\n\n";

    my $trace = (not $rule->{'+asr'} and $self->debug);
    $self->trace("try_$ref") if $trace;

    my $match = $self->match_next($rule);
    if (not $match) {
        $self->trace("not_$ref") if $trace;
        return 0;
    }

    # Call receiver callbacks
    $self->trace("got_$ref") if $trace;
    if (not $rule->{'+asr'} and not $parent->{'-skip'}) {
        my $callback = "got_$ref";
        if (my $sub = $self->receiver->can($callback)) {
            $match = [ $sub->($self->receiver, $match->[0]) ];
        }
        elsif (not $parent->{'-pass'}) {
            $match = [ @$match ? { $ref => $match->[0] } : () ];
        }
    }

    return $match;
}

my $terminater = 0;
sub match_rgx {
    my ($self, $regexp, $parent) = @_;

    my $start = pos($self->{buffer}) = $self->position;
    die "Your grammar seems to not terminate at end of stream"
        if $start >= length $self->{buffer} and $terminater++ > 1000;
    $self->{buffer} =~ /$regexp/g or return 0;
    my $finish = pos($self->{buffer});
    no strict 'refs';
    my $match = [ map $$_, 1..$#+ ];
    $match = [ $match ] if $#+ > 1;

    $self->position($finish);

    return $match;
}

sub match_all {
    my ($self, $list, $parent) = @_;
    my $pos = $self->position;
    my $set = [];
    my $len = 0;
    for my $elem (@$list) {
        if (my $match = $self->match_next($elem)) {
            next if $elem->{'+asr'} or $elem->{'-skip'};
            push @$set, @$match;
            $len++;
        }
        else {
            $self->position($pos);
            return 0;
        }
    }
    $set = [ $set ] if $len > 1;
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
    my $column = $self->position - rindex($self->buffer, "\n", $self->position);
    my $context = substr($self->buffer, $self->position, 50);
    $context =~ s/\n/\\n/g;
    my $position = $self->position;
    my $error = <<"...";
Error parsing Pegex document:
  msg: $msg
  line: $line
  column: $column
  context: "$context"
  position: $position
...
    if ($self->throw_on_error) {
        require Carp;
        Carp::croak($error);
    }
    $@ = $error;
    return 0;
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
