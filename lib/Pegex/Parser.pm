##
# name:      Pegex::Parser
# abstract:  Pegex Parser Runtime
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011, 2012
# see:
# - Pegex::Grammar
# - Pegex::Receiver

package Pegex::Parser;
use Pegex::Base;

use Scalar::Util;
use Pegex::Input;

# Grammar object or class
has grammar => ();
# Receiver object or class
has receiver => (
    default => sub {
        require Pegex::Receiver;
        Pegex::Receiver->new();
    },
    lazy => 1,
);

#
# Parser options
#

# Allow errors to not be thrown
has throw_on_error => (
    default => sub {1},
);

# Wrap results in hash with rule name for key
has wrap => (
    default => sub {
        $_[0]->receiver->{wrap};
    },
);

# # Allow a partial parse
# has 'partial' => default => sub {0};

# Internal properties.
has input => ();            # Input object to read from
has buffer => ();           # Input buffer to parse
has error => ();            # Error message goes here
has position => (           # Current position in buffer
    default => sub {0},
);
has farthest => (           # Farthest point matched in buffer
    default => sub {0},
);
# Loop counter for RE non-terminating spin prevention
has re_count => (
    default => sub {0},
);

# Debug the parsing of input.
has 'debug' => (
    default => sub {
        exists($ENV{PERL_PEGEX_DEBUG}) ? $ENV{PERL_PEGEX_DEBUG} :
        defined($Pegex::Parser::Debug) ? $Pegex::Parser::Debug :
        0;
    },
);

sub BUILD {
    my $self = shift;
    my $grammar = $self->grammar;
    my $receiver = $self->receiver;
    if ($grammar and not ref $grammar) {
        $self->{grammar} = $grammar->new;
    }
    if ($receiver and not ref $receiver) {
        $self->receiver($receiver->new);
    }
}

sub parse {
    my ($self, $input, $start_rule) = @_;
    $self->{position} = 0;

    die "Usage: " . ref($self) . '->parse($input [, $start_rule]'
        unless 2 <= @_ and @_ <= 3;

    $input = Pegex::Input->new(string => $input)
        unless ref $input and UNIVERSAL::isa($input, 'Pegex::Input');

    $self->{input} = $input;

    $self->{input}->open unless $self->{input}{_is_open};
    $self->{buffer} = $self->{input}->read;

    my $grammar = $self->{grammar}
        or die "No 'grammar'. Can't parse";

    my $tree = $self->{tree} = $grammar->{tree} //= $grammar->make_tree;
    $start_rule ||=
        $tree->{'+toprule'} ||
        ($tree->{'TOP'} ? 'TOP' : undef)
            or die "No starting rule for Pegex::Parser::parse";

    my $receiver = $self->{receiver}
        or die "No 'receiver'. Can't parse";

    # Add circular ref and weaken it.
    $self->{receiver}{parser} = $self;
    Scalar::Util::weaken($self->{receiver}{parser});

    # Do the parse
    my $match = $self->match($start_rule) or return;

    # Parse was successful!
    $self->{input}->close;
#     XXX $self->{receiver}->{data}, $match;
    return ($self->{receiver}{data} || $match);
}

sub match {
    my ($self, $rule) = @_;

    $self->{receiver}->initial($rule)
        if $self->{receiver}->can("initial");

    my $match = $self->match_next({'.ref' => $rule});
    if (not $match or $self->{position} < length($self->{buffer})) {
        $self->throw_error("Parse document failed for some reason");
        return;  # In case $self->throw_on_error is off
    }
    $match = $match->[0];

    $match = $self->{receiver}->final($match, $rule)
        if $self->{receiver}->can("final");

    $match = {$rule => []} unless $match;

    $match = $match->{TOP} || $match if $rule eq 'TOP';

    return $match;
}

sub get_min_max {
    my ($min, $max) = delete @{$_[1]}{qw(+min +max)};
    $_[1]->{'+mm'} = [
        ($min // (defined($max) ? 0 : 1)),
        ($max // (defined($min) ? 0 : 1)),
    ];
}

sub match_next {
    my ($self, $next) = @_;

    return $self->match_next_with_sep($next)
        if $next->{'.sep'};

    my ($min, $max) = @{$next->{'+mm'} || $self->get_min_max($next)};
    my $assertion = $next->{'+asr'} || 0;
    my ($rule, $kind);
    for (qw(ref rgx all any err code)) {
        $kind = $_, last if $rule = $next->{".$_"};
    }

    my ($match, $position, $count, $method) =
        ([], $self->{position}, 0, "match_$kind");

    while (my $return = $self->$method($rule, $next)) {
        $position = $self->{position} unless $assertion;
        $count++;
        push @$match, @$return;
        last if $max == 1;
    }
    if ($max != 1) {
        $match = [$match];
        # $self->set_position($position);
        if (($self->{position} = $position) > $self->{farthest}) {
            $self->{farthest} = $position;
            $self->{re_count} = 0;
        }
    }
    my $result = (($count >= $min and (not $max or $count <= $max)) ? 1 : 0)
        ^ ($assertion == -1);
    if (not($result) or $assertion) {
        # $self->set_position($position)
        if (($self->{position} = $position) > $self->{farthest}) {
            $self->{farthest} = $position;
            $self->{re_count} = 0;
        }
    }

    $match = [] if $next->{'-skip'};
    return ($result ? $match : 0);
}

sub match_next_with_sep {
    my ($self, $next) = @_;

    my ($min, $max) = @{$next->{'+mm'} || $self->get_min_max($next)};
    my ($rule, $kind);
    for (qw(ref rgx all any err code)) {
        $kind = $_, last if $rule = $next->{".$_"};
    }
    my $sep = $next->{'.sep'};

    my ($match, $position, $count, $method, $scount, $smin, $smax) =
        ([], $self->{position}, 0, "match_$kind", 0,
            @{$sep->{'+mm'} || $self->get_min_max($sep)});
    while (my $return = $self->$method($rule, $next)) {
        $position = $self->{position};
        $count++;
        push @$match, @$return;
        $return = $self->match_next($sep) or last;
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
    if ($count == $scount and not $sep->{'+eok'}) {
        # $self->set_position($position);
        if (($self->{position} = $position) > $self->{farthest}) {
            $self->{farthest} = $position;
            $self->{re_count} = 0;
        }
    }

    $match = [] if $next->{'-skip'};
    return ($result ? $match : 0);
}

sub match_ref {
    my ($self, $ref, $parent) = @_;
    my $rule = $self->{tree}{$ref};
    $rule ||= $self->can("match_rule_$ref")
            ? { '.code' => $ref }
            : die "\n\n*** No grammar support for '$ref'\n\n";

    my $trace = (not $rule->{'+asr'} and $self->{debug});
    $self->trace("try_$ref") if $trace;

    my $match = (ref($rule) eq 'CODE')
        ? $self->$rule()
        : $self->match_next($rule);
    if ($match) {
        $self->trace("got_$ref") if $trace;
        if (not $rule->{'+asr'} and not $parent->{'-skip'}) {
            if (my $sub = $self->{receiver}->can("got_$ref")) {
                $match = [ $sub->($self->{receiver}, $match->[0]) ];
            }
            elsif (
                $self->{wrap} ? not($parent->{'-pass'}) : $parent->{'-wrap'}
            ) {
                $match = [ @$match ? { $ref => $match->[0] } : () ];
            }
        }
    }
    else {
        $self->trace("not_$ref") if $trace;
        $match = 0;
    }

    return $match;
}

my $terminator_max = 1000;

sub match_rgx {
    my ($self, $regexp, $parent) = @_;

    # XXX Commented out code for switch from \G to ^. Use later.
    # my $position = $self->{position};
    my $position = pos($self->{buffer}) = $self->{position};

    my $terminator_iterator = ++$self->{re_count};
    if ($position >= length $self->{buffer} and $terminator_iterator > $terminator_max) {
        $self->throw_on_error(1);
        $self->throw_error("Your grammar seems to not terminate at end of stream");
    }

    # substr($self->{buffer}, $position) =~ $regexp or return 0;
    # my $position = $position + length(${^MATCH});
    $self->{buffer} =~ /$regexp/g or return 0;
    $position = pos($self->{buffer});

    no strict 'refs';
    my $match = [ map $$_, 1..$#+ ];
    $match = [ $match ] if $#+ > 1;

    # $self->set_position($position);
    if (($self->{position} = $position) > $self->{farthest}) {
        $self->{farthest} = $position;
        $self->{re_count} = 0;
    }

    return $match;
}

sub match_all {
    my ($self, $list, $parent) = @_;
    my $position = $self->{position};
    my $set = [];
    my $len = 0;
    for my $elem (@$list) {
        if (my $match = $self->match_next($elem)) {
            next if $elem->{'+asr'} or $elem->{'-skip'};
            push @$set, @$match;
            $len++;
        }
        else {
            # $self->set_position($position);
            if (($self->{position} = $position) > $self->{farthest}) {
                $self->{farthest} = $position;
                $self->{re_count} = 0;
            }
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

# sub set_position {
#     my ($self, $position) = @_;
#     $self->{position} = $position;
#     if ($position > $self->{farthest}) {
#         $self->{farthest} = $position;
#         $self->{re_count} = 0;
#     }
# }

sub trace {
    my ($self, $action) = @_;
    my $indent = ($action =~ /^try_/) ? 1 : 0;
    $self->{indent} ||= 0;
    $self->{indent}-- unless $indent;
    print STDERR ' ' x $self->{indent};
    $self->{indent}++ if $indent;
    my $snippet = substr($self->buffer, $self->position);
    $snippet = substr($snippet, 0, 30) . "..." if length $snippet > 30;
    $snippet =~ s/\n/\\n/g;
    print STDERR sprintf("%-30s", $action) .
        ($indent ? " >$snippet<\n" : "\n");
}

sub throw_error {
    my ($self, $msg) = @_;
    $self->format_error($msg);
    return 0 unless $self->{throw_on_error};
    require Carp;
    Carp::croak($self->{error});
}

sub format_error {
    my ($self, $msg) = @_;
    my $position = $self->{farthest};
    my $real_pos = $self->{position};

    my $line = @{[substr($self->{buffer}, 0, $position) =~ /(\n)/g]} + 1;
    my $column = $position - rindex($self->{buffer}, "\n", $position);

    my $pretext = substr(
        $self->{buffer},
        $position < 50 ? 0 : $position - 50,
        $position < 50 ? $position : 50
    );
    my $context = substr($self->{buffer}, $position, 50);
    $pretext =~ s/.*\n//gs;
    $context =~ s/\n/\\n/g;

    $@ = $self->{error} = <<"...";
Error parsing Pegex document:
  msg:      $msg
  line:     $line
  column:   $column
  context:  $pretext"$context"
  position: $position ($real_pos pre-lookahead)
...
}

1;

=head1 SYNOPSIS

    use Pegex::Parser;
    use SomeGrammarClass;
    use SomeReceiverClass;

    my $parser = Pegex::Parser->new(
        grammar => SomeGrammarClass->new,
        receiver => SomeReceiverClass->new,
    );

    my $result = $parser->parse($SomeInputText);

=head1 DESCRIPTION

Pegex::Parser is the Pegex component that provides the parsing engine runtime.
It requires a Grammar object and a Receiver object. It's C<parse()> method
takes an input that is expected to be matched by the grammar, and applies the
grammar rules to the input. As the grammar is applied the receiver is notified
of matches. The receiver is free to do whatever it wishes, but often times it
builds the data into a structure that is commonly known as an AST (Abstract
Syntax Tree).

When the parse method is complete it returns whatever object the receiver has
provided as the final result. If the grammar fails to match the input along
the way, the parse method will throw an error with much information about the
failure.
