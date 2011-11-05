##
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
# # Allow a partial parse
# has 'partial' => default => sub {0};
# Wrap results in hash with rule name for key
has 'wrap' => default => sub { $_[0]->receiver->wrap };

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

sub get_min_max {
    my ($self, $next) = @_;
    defined($next->{'+min'})
    ? defined($next->{'+max'})
        ? (@{$next}{qw'+min +max'})
        : ($next->{'+min'}, 0)
    : defined($next->{'+max'})
        ? (0, $next->{'+max'})
        : (1, 1);
}

sub match_next {
    my ($self, $next) = @_;

    return $self->match_next_with_sep($next)
        if $next->{'.sep'};

    my ($min, $max) = $self->get_min_max($next);
    my $assertion = $next->{'+asr'} || 0;
    my ($rule, $kind) = map {($next->{".$_"}, $_)}
        grep {$next->{".$_"}} qw(ref rgx all any err code) or XXX $next;

    my ($match, $position, $count, $method) =
        ([], $self->position, 0, "match_$kind");

# XXX Need to rethink this. match_all must be able to complete possible zero
# width matches at end of stream...
#     my $return;
#     while ($position < length($self->{buffer}) and
#         $return = $self->$method($rule, $next)) {

    while (my $return = $self->$method($rule, $next)) {
        $position = $self->position unless $assertion;
        $count++;
        push @$match, @$return;
        last if $max == 1;
    }
    if ($max != 1) {
        $match = [$match];
        $self->position($position);
    }
    my $result = (($count >= $min and (not $max or $count <= $max)) ? 1 : 0)
        ^ ($assertion == -1);
    $self->position($position)
        if not($result) or $assertion;

    $match = [] if $next->{'-skip'};
    return ($result ? $match : 0);
}

sub match_next_with_sep {
    my ($self, $next) = @_;

    my ($min, $max) = $self->get_min_max($next);
    my ($rule, $kind) = map {($next->{".$_"}, $_)}
        grep {$next->{".$_"}} qw(ref rgx all any err) or XXX $next;
    my $separator = $next->{'.sep'};

    my ($match, $position, $count, $method, $scount, $smin, $smax) =
        ([], $self->position, 0, "match_$kind", 0,
            $self->get_min_max($separator));
    if ($separator->{'+bok'}) {
        # TODO refactor with matching code below
        if (my $return = $self->match_next($separator)) {
            $position = $self->position;
            my @return = @$return;
            if (@return) {
                @return = @{$return[0]} if $smax != 1;
                push @$match, @return;
            }
        }
    }
    while (my $return = $self->$method($rule, $next)) {
        $position = $self->position;
        $count++;
        push @$match, @$return;
        $return = $self->match_next($separator) or last;
        my @return = @$return;
        if (@return) {
            @return = @{$return[0]} if $smax != 1;
            push @$match, @return;
        }
        $scount++;
    }
    if ($max != 1) {
        $match = [$match];
    }
    my $result = (($count >= $min and (not $max or $count <= $max)) ? 1 : 0);
    $self->revert_back($position)
        if $count == $scount and not $separator->{'+eok'};

    $match = [] if $next->{'-skip'};
    return ($result ? $match : 0);
}

sub revert_back {
    my ($self, $position) = @_;
    $self->position($position);
}

sub match_ref {
    my ($self, $ref, $parent) = @_;
    my $rule = $self->grammar->tree->{$ref};
    $rule ||= $self->can("match_rule_$ref")
            ? { '.code' => $ref } 
            : die "\n\n*** No grammar support for '$ref'\n\n";

    my $trace = (not $rule->{'+asr'} and $self->debug);
    $self->trace("try_$ref") if $trace;

    my $match = (ref($rule) eq 'CODE')
        ? $self->$rule()
        : $self->match_next($rule);
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
        elsif ($self->wrap ? not($parent->{'-pass'}) : $parent->{'-wrap'}) {
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
            $self->revert_back($pos);
            return 0;
        }
    }
    $set = [ $set ] if $len > 1;
    return $set;
}

sub match_any {
    my ($self, $list, $parent) = @_;
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

sub match_code {
    my ($self, $code) = @_;
    my $method = "match_rule_$code";
    return $self->$method();
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
