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

use Pegex::Input;

use Scalar::Util;

# Grammar object or class
has grammar => (required => 1);

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
has throw_on_error => 1;

# # Allow a partial parse
# has 'partial' => 0;

# Internal properties.
has input => ();            # Input object to read from
has buffer => ();           # Input buffer to parse
has length => ();           # Length of buffer
has error => ();            # Error message goes here
has position => 0;          # Current position in buffer
has farthest => 0;          # Farthest point matched in buffer
has optimized => 0;         # Parser object has been optimized

has rule => ();             # The current rule name.
has parent => ();           # The grammar object pointing to the current rule.

# Debug the parsing of input.
has 'debug' => (
    default => sub {
        exists($ENV{PERL_PEGEX_DEBUG}) ? $ENV{PERL_PEGEX_DEBUG} :
        defined($Pegex::Parser::Debug) ? $Pegex::Parser::Debug :
        0;
    },
);

sub BUILD {
    my ($self) = @_;
    my $grammar = $self->grammar;
    my $receiver = $self->receiver;
    if ($grammar and not ref $grammar) {
        eval "require $grammar";
        $self->{grammar} = $grammar->new;
    }
    if ($receiver and not ref $receiver) {
        eval "require $receiver";
        $self->{receiver} = $receiver->new;
    }
}

sub parse {
    my ($self, $input, $start) = @_;
    $self->{position} = 0; # XXX Currently needed for repeated calls.

    die 'Usage: ->parse($input [, $start_rule]'
        unless 2 <= @_ and @_ <= 3;

    $input = Pegex::Input->new(string => $input)
        unless ref $input and UNIVERSAL::isa($input, 'Pegex::Input');

    $self->{input} = $input;

    $self->{input}->open unless $self->{input}{_is_open};
    $self->{buffer} = $self->{input}->read;
    $self->{length} = length ${$self->{buffer}};

    my $grammar = $self->{grammar}
        or die "No 'grammar'. Can't parse";

    my $tree = $self->{tree} = $grammar->{tree} //= $grammar->make_tree;

    my $start_rule_ref = $start ||
        $tree->{'+toprule'} ||
        ($tree->{'TOP'} ? 'TOP' : undef)
            or die "No starting rule for Pegex::Parser::parse";

    $self->optimize_grammar($start_rule_ref);

    my $receiver = $self->{receiver}
        or die "No 'receiver'. Can't parse";

    # Add circular ref and weaken it.
    $self->{receiver}{parser} = $self;
    Scalar::Util::weaken($self->{receiver}{parser});

    if ($self->{receiver}->can("initial")) {
        @{$self}{'rule', 'parent'} = ($start_rule_ref, {});
        $self->{receiver}->initial();
    }

    my $match = $self->match_ref($start_rule_ref, {});

    $self->{input}->close;

    if (not $match or $self->{position} < $self->{length}) {
        $self->throw_error("Parse document failed for some reason");
        return;  # In case $self->throw_on_error is off
    }

    if ($self->{receiver}->can("final")) {
        @{$self}{'rule', 'parent'} = ($start_rule_ref, {});
        $match = [ $self->{receiver}->final(@$match) ];
    }

    return $match->[0];
}

sub optimize_grammar {
    my ($self, $start) = @_;
    return if $self->{optimized}++;
    my $tree = $self->{tree};
    for my $name (keys %$tree) {
        my $node = $tree->{$name};
        next unless ref($node);
        $self->optimize_node($node);
    }
    $self->optimize_node({'.ref' => $start});
}

sub optimize_node {
    my ($self, $node) = @_;

    for (qw(ref rgx all any err code xxx)) {
        die if $_ eq 'xxx';
        if ($node->{rule} = $node->{".$_"}) {
            $node->{kind} = $_;
            $node->{method} = $self->can("match_$_") or die;
            last;
        }
    }

    my ($min, $max) = @{$node}{'+min', '+max'};
    $node->{'+min'} //= defined($max) ? 0 : 1;
    $node->{'+max'} //= defined($min) ? 0 : 1;
    $node->{'+asr'} //= 0;

    if ($node->{kind} =~ /(?:all|any)/) {
        $self->optimize_node($_) for @{$node->{rule}};
    }
    elsif ($node->{kind} eq 'ref') {
        my $ref = $node->{rule};
        my $rule = $self->{tree}{$ref};
        if (my $action = $self->{receiver}->can("got_$ref")) {
            $rule->{action} = $action;
        }
        elsif (my $gotrule = $self->{receiver}->can("gotrule")) {
            $rule->{action} = $gotrule;
        }
        $node->{method} = $self->can("match_ref_trace")
            if $self->{debug};
    }
    if (my $sep = $node->{'.sep'}) {
        $self->optimize_node($sep);
    }
}

sub match_next {
    my ($self, $next) = @_;

    return $self->match_next_with_sep($next)
        if $next->{'.sep'};

    my ($rule, $method, $kind, $min, $max, $assertion) =
        @{$next}{'rule', 'method', 'kind', '+min', '+max', '+asr'};

    my ($position, $match, $count) =
        ($self->{position}, [], 0);

    while (my $return = $method->($self, $rule, $next)) {
        $position = $self->{position} unless $assertion;
        $count++;
        push @$match, @$return;
        last if $max == 1;
    }
    if ($max != 1) {
        $match = [$match];
        if (($self->{position} = $position) > $self->{farthest}) {
            $self->{farthest} = $position;
        }
    }
    my $result = (($count >= $min and (not $max or $count <= $max)) ? 1 : 0)
        ^ ($assertion == -1);
    if (not($result) or $assertion) {
        if (($self->{position} = $position) > $self->{farthest}) {
            $self->{farthest} = $position;
        }
    }

    return ($result ? $next->{'-skip'} ? [] : $match : 0);
}

sub match_next_with_sep {
    my ($self, $next) = @_;

    my ($rule, $method, $kind, $min, $max, $sep) =
        @{$next}{'rule', 'method', 'kind', '+min', '+max', '.sep'};

    my ($position, $match, $count, $scount, $smin, $smax) =
        ($self->{position}, [], 0, 0, @{$sep}{'+min', '+max'});

    while (my $return = $method->($self, $rule, $next)) {
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
        if (($self->{position} = $position) > $self->{farthest}) {
            $self->{farthest} = $position;
        }
    }

    return ($result ? $next->{'-skip'} ? [] : $match : 0);
}

my $dummy = [1];
sub match_ref {
    my ($self) = @_; # $self, $ref, $parent
    my $rule = $self->{tree}{$_[1]};

    my $match = $self->match_next($rule) or return 0;
    return $dummy unless $rule->{action};
    @{$self}{'rule', 'parent'} = @_[1,2];
    [ $rule->{action}->($self->{receiver}, @$match) ];
}

sub match_rgx {
    my ($self, $regexp) = @_;
    my $buffer = $self->{buffer};

    my $position = pos($$buffer) = $self->{position};

    $$buffer =~ /$regexp/g or return 0;
    $position = pos($$buffer);

    no strict 'refs';
    my $match = [ map $$_, 1..$#+ ];
    $match = [ $match ] if $#+ > 1;

    if (($self->{position} = $position) > $self->{farthest}) {
        $self->{farthest} = $position;
    }

    return $match;
}

sub match_all {
    my ($self, $list) = @_;
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
            if (($self->{position} = $position) > $self->{farthest}) {
                $self->{farthest} = $position;
            }
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

sub match_code {
    my ($self, $code) = @_;
    my $method = "match_rule_$code";
    return $self->$method();
}

sub match_ref_trace {
    my ($self, $ref) = @_;
    my $rule = $self->{tree}{$ref};
    my $trace = not $rule->{'+asr'};
    $self->trace("try_$ref") if $trace;
    my $result;
    if ($result = $self->match_ref($ref)) {
        $self->trace("got_$ref") if $trace;
    }
    else {
        $self->trace("not_$ref") if $trace;
    }
    return $result;
}

sub trace {
    my ($self, $action) = @_;
    my $indent = ($action =~ /^try_/) ? 1 : 0;
    $self->{indent} ||= 0;
    $self->{indent}-- unless $indent;
    print STDERR ' ' x $self->{indent};
    $self->{indent}++ if $indent;
    my $snippet = substr(${$self->{buffer}}, $self->{position});
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
    my $buffer = $self->{buffer};
    my $position = $self->{farthest};
    my $real_pos = $self->{position};

    my $line = @{[substr($$buffer, 0, $position) =~ /(\n)/g]} + 1;
    my $column = $position - rindex($$buffer, "\n", $position);

    my $pretext = substr(
        $$buffer,
        $position < 50 ? 0 : $position - 50,
        $position < 50 ? $position : 50
    );
    my $context = substr($$buffer, $position, 50);
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
grammar rules to the input. As the grammar is applied, the receiver is notified
of matches. The receiver is free to do whatever it wishes, but often times it
builds the data into a structure that is commonly known as a Parse Tree.

When the parse method is complete it returns whatever object the receiver has
provided as the final result. If the grammar fails to match the input along
the way, the parse method will throw an error with much information about the
failure.
