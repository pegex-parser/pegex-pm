package Pegex::Parser;
use Pegex::Base;
use Pegex::Input;
use Pegex::Optimizer;
use Scalar::Util;

{
    package Pegex::Constant;

    our $Null = [];
    our $Dummy = [];
}

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

has throw_on_error => 1;

sub parse {
    my ($self, $input, $start) = @_;

    if ($start) {
        $start =~ s/-/_/g;
    }

    $self->{position} = 0;
    $self->{farthest} = 0;

    if (not UNIVERSAL::isa($input, 'Pegex::Input')) {
        $input = Pegex::Input->new(string => $input);
    }
    $self->{input} = $input;
    $self->{input}->open unless $self->{input}{_is_open};
    $self->{buffer} = $self->{input}->read;
    $self->{length} = length ${$self->{buffer}};

    die "No 'grammar'. Can't parse" unless $self->{grammar};

    $self->{grammar}{tree} = $self->{grammar}->make_tree
        unless defined $self->{grammar}{tree};

    my $start_rule_ref = $start ||
        $self->{grammar}{tree}{'+toprule'} ||
        ($self->{grammar}{tree}{'TOP'} ? 'TOP' : undef)
            or die "No starting rule for Pegex::Parser::parse";

    die "No 'receiver'. Can't parse" unless $self->{receiver};

    Pegex::Optimizer->new(
        parser => $self,
        grammar => $self->{grammar},
        receiver => $self->{receiver},
    )->optimize_grammar($start_rule_ref);

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

sub match_next {
    my ($self, $next) = @_;

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
    if (not $count and $min == 0 and $kind eq 'all') {
        $match = [[]];
    }
    if ($max != 1) {
        if ($next->{-flat}) {
            $match = [ map { (ref($_) eq 'ARRAY') ? (@$_) : ($_) } @$match ];
        }
        else {
            $match = [$match]
        }
        $self->{farthest} = $position
            if ($self->{position} = $position) > $self->{farthest};
    }
    my $result = ($count >= $min and (not $max or $count <= $max))
        ^ ($assertion == -1);
    if (not($result) or $assertion) {
        $self->{farthest} = $position
            if ($self->{position} = $position) > $self->{farthest};
    }

    # YYY ($result ? $next->{'-skip'} ? [] : $match : 0) if $main::x;
    return ($result ? $next->{'-skip'} ? [] : $match : 0);
}

sub match_ref {
    my ($self, $ref, $parent) = @_;
    my $rule = $self->{grammar}{tree}{$ref}
        or die "No rule defined for '$ref'";
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

sub match_ref_trace {
    my ($self, $ref, $parent) = @_;
    my $asr = $parent->{'+asr'};
    my $note =
        $asr == -1 ? '(!)' :
        $asr == 1 ? '(=)' :
        '';
    $self->trace("try_$ref$note");
    my $result;
    if ($result = $self->match_ref($ref)) {
        $self->trace("got_$ref$note");
    }
    else {
        $self->trace("not_$ref$note");
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
