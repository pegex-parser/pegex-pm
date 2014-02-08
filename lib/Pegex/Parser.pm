package Pegex::Parser;

use Pegex::Input;

use Scalar::Util;

{
    package Pegex::Constant;

    our $Null = [];
    our $Dummy = [];
}

package Pegex::Parser;

use Pegex::Base;

has grammar => (required => 1);
has receiver => ();
has input => ();

has rule => ();
has parent => ();
has 'debug' => (
    default => sub {
        exists($ENV{PERL_PEGEX_DEBUG}) ? $ENV{PERL_PEGEX_DEBUG} :
        defined($Pegex::Parser::Debug) ? $Pegex::Parser::Debug :
        0;
    },
);

has position => 0;
has farthest => 0;
has optimized => 0;

has throw_on_error => 1;

sub parse {
    my ($self, $input, $start) = @_;
    $self->{position} = 0;

    if (not UNIVERSAL::isa($input, 'Pegex::Input')) {
        $input = Pegex::Input->new(string => $input);
    }
    $self->{input} = $input;
    $self->{input}->open unless $self->{input}{_is_open};
    $self->{buffer} = $self->{input}->read;
    $self->{length} = length ${$self->{buffer}};

    die "No 'grammar'. Can't parse" unless $self->{grammar};

    $self->{grammar}->{tree} = $self->{grammar}->make_tree
        unless defined $self->{grammar}->{tree};
    $self->{tree} = $self->{grammar}->{tree};

    my $start_rule_ref = $start ||
        $self->{tree}->{'+toprule'} ||
        ($self->{tree}->{'TOP'} ? 'TOP' : undef)
            or die "No starting rule for Pegex::Parser::parse";

    die "No 'receiver'. Can't parse" unless $self->{receiver};

    $self->optimize_grammar($start_rule_ref);

    # Add circular ref and weaken it.
    $self->{receiver}{parser} = $self;
    Scalar::Util::weaken($self->{receiver}{parser});

    if ($self->{receiver}->can("initial")) {
        $self->{rule} = $start_rule_ref;
        $self->{parent} = {};
        $self->{receiver}->initial();
    }

    my $match = $self->match_ref($start_rule_ref, {});

    $self->{input}->close;

    if (not $match or $self->{position} < $self->{length}) {
        $self->throw_error("Parse document failed for some reason");
        return;  # In case $self->throw_on_error is off
    }

    if ($self->{receiver}->can("final")) {
        $self->{rule} = $start_rule_ref;
        $self->{parent} = {};
        # XXX mismatch with ruby port
        $match = [ $self->{receiver}->final(@$match) ];
    }

    return $match->[0];
}

sub optimize_grammar {
    my ($self, $start) = @_;
    return if $self->{optimized};
    while (my ($name, $node) = each %{$self->{tree}}) {
        next unless ref($node);
        $self->optimize_node($node);
    }
    $self->optimize_node({'.ref' => $start});
    $self->{optimized} = 1;
}

sub optimize_node {
    my ($self, $node) = @_;

    for my $kind (qw(ref rgx all any err code xxx)) {
        die if $kind eq 'xxx';
        if ($node->{rule} = $node->{".$kind"}) {
            $node->{kind} = $kind;
            $node->{method} = $self->can("match_$kind") or die;
            last;
        }
    }

    my ($min, $max) = @{$node}{'+min', '+max'};
    $node->{'+min'} = defined($max) ? 0 : 1
        unless defined $node->{'+min'};
    $node->{'+max'} = defined($min) ? 0 : 1
        unless defined $node->{'+max'};
    $node->{'+asr'} = 0
        unless defined $node->{'+asr'};

    if ($node->{kind} =~ /^(?:all|any)$/) {
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
    elsif ($node->{kind} eq 'rgx') {
      # XXX $node;
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
        $self->{farthest} = $position
            if ($self->{position} = $position) > $self->{farthest};
    }
    my $result = ($count >= $min and (not $max or $count <= $max))
        ^ ($assertion == -1);
    if (not($result) or $assertion) {
        $self->{farthest} = $position
            if ($self->{position} = $position) > $self->{farthest};
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
        push @$match, $smax == 1 ? @$return : @{$return->[0]} if @$return;
        $scount++;
    }
    $match = [$match] if $max != 1;
    my $result = ($count >= $min and ($max == 0 or $count <= $max));
    if ($count == $scount and not $sep->{'+eok'}) {
        $self->{farthest} = $position
            if ($self->{position} = $position) > $self->{farthest};
    }

    return ($result ? $next->{'-skip'} ? [] : $match : 0);
}

sub match_ref {
    my ($self, $ref, $parent) = @_;
    my $rule = $self->{tree}{$ref};
    my $match = $self->match_next($rule) or return 0;
    return $Pegex::Constant::Dummy unless $rule->{action};
    @{$self}{'rule', 'parent'} = ($ref, $parent);
    # XXX API mismatch
    [ $rule->{action}->($self->{receiver}, @$match) ];
}

sub match_rgx {
    my ($self, $regexp) = @_;
    my $buffer = $self->{buffer};

    pos($$buffer) = $self->{position};

    $$buffer =~ /$regexp/g or return 0;
    $self->{position} = pos($$buffer);

    no strict 'refs';
    my $match = [ map $$_, 1..$#+ ];
    $match = [ $match ] if $#+ > 1;
    $self->{farthest} = $self->{position}
        if $self->{position} > $self->{farthest};
    return $match;
}

sub match_all {
    my ($self, $list) = @_;
    my $position = $self->{position};
    my $set = [];
    my $len = 0;
    for my $elem (@$list) {
        if (my $match = $self->match_next($elem)) {
            if (not ($elem->{'+asr'} or $elem->{'-skip'})) {
                push @$set, @$match;
                $len++;
            }
        }
        else {
            $self->{farthest} = $position
                if ($self->{position} = $position) > $self->{farthest};
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

# TODO not supported yet
# sub match_code {
#     my ($self, $code) = @_;
#     my $method = "match_rule_$code";
#     return $self->$method();
# }

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
    $@ = $self->{error} = $self->format_error($msg);
    return undef unless $self->{throw_on_error};
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

    return <<"...";
Error parsing Pegex document:
  msg:      $msg
  line:     $line
  column:   $column
  context:  $pretext$context
  ${\ (' ' x (length($pretext) + 10) . '^')}
  position: $position ($real_pos pre-lookahead)
...
}

1;
