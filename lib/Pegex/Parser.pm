package Pegex::Parser;
use Pegex::Base;
no warnings qw( recursion );

use Pegex::Input;
use Pegex::Optimizer;
use Scalar::Util;

has grammar => (required => 1);
has receiver => ();
has input => ();

has recursion_count => 0;
has iteration_count => 0;

has debug => ();
has debug_indent => ();
has debug_color => ();
has debug_got_color => ();
has debug_not_color => ();

has recursion_limit => ();
has recursion_warn_limit => ();
has iteration_limit => ();

sub BUILD {
    my ($self) = @_;

    $self->{throw_on_error} ||= 1;

    $self->{debug} =
        defined($ENV{PERL_PEGEX_DEBUG}) ? $ENV{PERL_PEGEX_DEBUG} :
        defined($Pegex::Parser::Debug) ? $Pegex::Parser::Debug : 0
        unless defined($self->{debug});

    $self->{debug_indent} =
        defined($ENV{PERL_PEGEX_DEBUG_INDENT}) ? $ENV{PERL_PEGEX_DEBUG_INDENT} :
        defined($Pegex::Parser::DebugIndent) ? $Pegex::Parser::DebugIndent : 1
        unless defined($self->{debug_indent});
    $self->{debug_indent} = 1 if (
        not length $self->{debug_indent}
        or $self->{debug_indent} =~ tr/0-9//c
        or $self->{debug_indent} < 0
    );

    if ($self->{debug}) {
        $self->{debug_color} =
            defined($ENV{PERL_PEGEX_DEBUG_COLOR}) ? $ENV{PERL_PEGEX_DEBUG_COLOR} :
            defined($Pegex::Parser::DebugColor) ? $Pegex::Parser::DebugColor : 1
            unless defined($self->{debug_color});
        my ($got, $not);
        ($self->{debug_color}, $got, $not) =
            split / *, */, $self->{debug_color};
        $got ||= 'bright_green';
        $not ||= 'bright_red';
        $_ = [split ' ', $_] for ($got, $not);
        $self->{debug_got_color} = $got;
        $self->{debug_not_color} = $not;
        my $c = defined($self->{debug_color}) ? $self->{debug_color} : 1;
        $self->{debug_color} =
            $c eq 'always' ? 1 :
            $c eq 'auto' ? (-t STDERR ? 1 : 0) :
            $c eq 'never' ? 0 :
            $c =~ /^\d+$/ ? $c : 0;
        if ($self->{debug_color}) {
            require Term::ANSIColor;
            if ($Term::ANSIColor::VERSION < 3.00) {
                s/^bright_// for
                    @{$self->{debug_got_color}},
                    @{$self->{debug_not_color}};
            }
        }
    }
    $self->{recursion_limit} =
        defined($ENV{PERL_PEGEX_RECURSION_LIMIT}) ? $ENV{PERL_PEGEX_RECURSION_LIMIT} :
        defined($Pegex::Parser::RecursionLimit) ? $Pegex::Parser::RecursionLimit : 0
        unless defined($self->{recursion_limit});
    $self->{recursion_warn_limit} =
        defined($ENV{PERL_PEGEX_RECURSION_WARN_LIMIT}) ? $ENV{PERL_PEGEX_RECURSION_WARN_LIMIT} :
        defined($Pegex::Parser::RecursionWarnLimit) ? $Pegex::Parser::RecursionWarnLimit : 0
        unless defined($self->{recursion_warn_limit});
    $self->{iteration_limit} =
        defined($ENV{PERL_PEGEX_ITERATION_LIMIT}) ? $ENV{PERL_PEGEX_ITERATION_LIMIT} :
        defined($Pegex::Parser::IterationLimit) ? $Pegex::Parser::IterationLimit : 0
        unless defined($self->{iteration_limit});
}

# XXX Add an optional $position argument. Default to 0. This is the position
# to start parsing. Set position and farthest below to this value. Allows for
# sub-parsing. Need to somehow return the finishing position of a subparse.
# Maybe this all goes in a subparse() method.
sub parse {
    my ($self, $input, $start) = @_;

    $start =~ s/-/_/g if $start;

    $self->{position} = 0;
    $self->{farthest} = 0;

    $self->{input} = (not ref $input)
      ? Pegex::Input->new(string => $input)
      : $input;

    $self->{input}->open
        unless $self->{input}{_is_open};
    $self->{buffer} = $self->{input}->read;
    $self->{last_line_pos} = 0;
    $self->{last_line} = 1;

    $self->{grammar}{tree} ||= $self->{grammar}->make_tree;

    my $start_rule_ref = $start ||
        $self->{grammar}{tree}{'+toprule'} ||
        $self->{grammar}{tree}{'TOP'} & 'TOP' or
        die "No starting rule for Pegex::Parser::parse";

    die "No 'receiver'. Can't parse"
        unless $self->{receiver};

    my $optimizer = Pegex::Optimizer->new(
        parser => $self,
        grammar => $self->{grammar},
        receiver => $self->{receiver},
    );

    $optimizer->optimize_grammar($start_rule_ref);

    # Add circular ref and weaken it.
    $self->{receiver}{parser} = $self;
    Scalar::Util::weaken($self->{receiver}{parser});

    if ($self->{receiver}->can("initial")) {
        $self->{rule} = $start_rule_ref;
        $self->{parent} = {};
        $self->{receiver}->initial();
    }

    local *match_next;
    {
        no warnings 'redefine';
        *match_next = (
            $self->{recursion_warn_limit} or
            $self->{recursion_limit} or
            $self->{iteration_limit}
         ) ? \&match_next_with_limit :
             \&match_next_normal;
    }

    my $match = $self->debug ? do {
        my $method = $optimizer->make_trace_wrapper(\&match_ref);
        $self->$method($start_rule_ref, {'+asr' => 0});
    } : $self->match_ref($start_rule_ref, {});

    $self->{input}->close;

    if (not $match or $self->{position} < length ${$self->{buffer}}) {
        $self->throw_error("Parse document failed for some reason");
        return;  # In case $self->throw_on_error is off
    }

    if ($self->{receiver}->can("final")) {
        $self->{rule} = $start_rule_ref;
        $self->{parent} = {};
        $match = [ $self->{receiver}->final(@$match) ];
    }

    $match->[0];
}

sub match_next_normal {
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
    }
    my $result = ($count >= $min and (not $max or $count <= $max))
        ^ ($assertion == -1);
    if (not($result) or $assertion) {
        $self->{farthest} = $position
            if ($self->{position} = $position) > $self->{farthest};
    }

    ($result ? $next->{'-skip'} ? [] : $match : 0);
}

sub match_next_with_limit {
    my ($self, $next) = @_;

    sub limit_msg {
        "Deep recursion ($_[0] levels) on Pegex::Parser::match_next\n";
    }

    $self->{iteration_count}++;
    $self->{recursion_count}++;

    if (
        $self->{recursion_limit} and
        $self->{recursion_count} >= $self->{recursion_limit}
    ) { die limit_msg $self->{recursion_count} }
    elsif (
        $self->{recursion_warn_limit} and
        not ($self->{recursion_count} % $self->{recursion_warn_limit})
    ) { warn limit_msg $self->{recursion_count} }
    elsif (
        $self->{iteration_limit} and
        $self->{iteration_count} > $self->{iteration_limit}
    ) { die "Pegex iteration limit of $self->{iteration_limit} reached." }

    my $result = $self->match_next_normal($next);

    $self->{recursion_count}--;

    return $result;
}

sub match_rule {
    my ($self, $position, $match) = (@_, []);
    $self->{position} = $position;
    $self->{farthest} = $position
        if $position > $self->{farthest};
    $match = [ $match ] if @$match > 1;
    my ($ref, $parent) = @{$self}{'rule', 'parent'};
    my $rule = $self->{grammar}{tree}{$ref}
        or die "No rule defined for '$ref'";

    [ $rule->{action}->($self->{receiver}, @$match) ];
}

sub match_ref {
    my ($self, $ref, $parent) = @_;
    my $rule = $self->{grammar}{tree}{$ref}
        or die "No rule defined for '$ref'";
    my $match = $self->match_next($rule) or return;
    return $Pegex::Constant::Dummy unless $rule->{action};
    @{$self}{'rule', 'parent'} = ($ref, $parent);

    # XXX Possible API mismatch.
    # Not sure if we should "splat" the $match.
    [ $rule->{action}->($self->{receiver}, @$match) ];
}

sub match_rgx {
    my ($self, $regexp) = @_;
    my $buffer = $self->{buffer};

    pos($$buffer) = $self->{position};
    $$buffer =~ /$regexp/g or return;

    $self->{position} = pos($$buffer);

    $self->{farthest} = $self->{position}
        if $self->{position} > $self->{farthest};

    no strict 'refs';
    my $captures = [ map $$_, 1..$#+ ];
    $captures = [ $captures ] if $#+ > 1;

    return $captures;
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
            return;
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
    return;
}

sub match_err {
    my ($self, $error) = @_;
    $self->throw_error($error);
}

sub trace {
    my ($self, $action) = @_;
    my $indent = ($action =~ /^try_/) ? 1 : 0;
    $self->{indent} ||= 0;
    $self->{indent}-- unless $indent;

    $action = (
        $action =~ m/got_/ ?
            Term::ANSIColor::colored($self->{debug_got_color}, $action) :
        $action =~ m/not_/ ?
            Term::ANSIColor::colored($self->{debug_not_color}, $action) :
        $action
    ) if $self->{debug_color};

    print STDERR ' ' x ($self->{indent} * $self->{debug_indent});
    $self->{indent}++ if $indent;
    my $snippet = substr(${$self->{buffer}}, $self->{position});
    $snippet = substr($snippet, 0, 30) . "..."
        if length $snippet > 30;
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

    my $line = $self->line($position);
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

# TODO Move this to a Parser helper role/subclass
sub line_column {
    my ($self, $position) = @_;
    $position ||= $self->{position};
    my $buffer = $self->{buffer};
    my $line = $self->line($position);
    my $column = $position - rindex($$buffer, "\n", $position);
    return [$line, $column];
}

sub line {
    my ($self, $position) = @_;
    $position ||= $self->{position};
    my $buffer = $self->{buffer};
    my $last_line = $self->{last_line};
    my $last_line_pos = $self->{last_line_pos};
    my $len = $position - $last_line_pos;
    if ($len == 0) {
        return $last_line;
    }
    my $line;
    if ($len < 0) {
        $line = $last_line - scalar substr($$buffer, $position, -$len) =~ tr/\n//;
    } else {
        $line = $last_line + scalar substr($$buffer, $last_line_pos, $len) =~ tr/\n//;
    }
    $self->{last_line} = $line;
    $self->{last_line_pos} = $position;
    return $line;
}

# XXX Need to figure out what uses this. (sample.t)
{
    package Pegex::Constant;
    our $Null = [];
    our $Dummy = [];
}

1;
