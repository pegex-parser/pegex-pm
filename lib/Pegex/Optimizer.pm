package Pegex::Optimizer;
use Pegex::Base;

has parser => (required => 1);
has grammar => (required => 1);
has receiver => (required => 1);

sub optimize_grammar {
    my ($self, $start) = @_;
    my $tree = $self->grammar->{tree};
    return if $tree->{'+optimized'};
    $self->set_max_parse if $self->parser->{maxparse};
    $self->{extra} = {};
    while (my ($name, $node) = each %$tree) {
        next unless ref($node);
        $self->optimize_node($node);
    }
    $self->optimize_node({'.ref' => $start});
    my $extra = delete $self->{extra};
    for my $key (%$extra) {
        $tree->{$key} = $extra->{$key};
    }
    $tree->{'+optimized'} = 1;
}

sub optimize_node {
    my ($self, $node) = @_;

    my ($min, $max) = @{$node}{'+min', '+max'};
    $node->{'+min'} = defined($max) ? 0 : 1
        unless defined $node->{'+min'};
    $node->{'+max'} = defined($min) ? 0 : 1
        unless defined $node->{'+max'};
    $node->{'+asr'} = 0
        unless defined $node->{'+asr'};

    for my $kind (qw(ref rgx all any err code xxx)) {
        return if $kind eq 'xxx';
        if ($node->{rule} = $node->{".$kind"}) {
            delete $node->{".$kind"};
            $node->{kind} = $kind;
            if ($kind eq 'ref') {
                my $rule = $node->{rule} or die;
                if (my $method = $self->grammar->can("rule_$rule")) {
                    $node->{method} = $self->make_method_wrapper($method);
                }
                elsif (not $self->grammar->{tree}{$rule}) {
                    if (my $method = $self->grammar->can("$rule")) {
                        warn <<"...";
Warning:

    You have a method called '$rule' in your grammar.
    It should probably be called 'rule_$rule'.

...
                    }
                    die "No rule '$rule' defined in grammar";
                }
            }
            $node->{method} ||= $self->parser->can("match_$kind") or die;
            last;
        }
    }

    if ($node->{kind} =~ /^(?:all|any)$/) {
        $self->optimize_node($_) for @{$node->{rule}};
    }
    elsif ($node->{kind} eq 'ref') {
        my $ref = $node->{rule};
        my $rule = $self->grammar->{tree}{$ref};
        $rule ||= $self->{extra}{$ref} = {};
        if (my $action = $self->receiver->can("got_$ref")) {
            $rule->{action} = $action;
        }
        elsif (my $gotrule = $self->receiver->can("gotrule")) {
            $rule->{action} = $gotrule;
        }
        if ($self->parser->{debug}) {
            $node->{method} = $self->make_trace_wrapper($node->{method});
        }
    }
    elsif ($node->{kind} eq 'rgx') {
      # XXX $node;
    }
}

sub make_method_wrapper {
    my ($self, $method) = @_;
    return sub {
        my ($parser, $ref, $parent) = @_;
        @{$parser}{'rule', 'parent'} = ($ref, $parent);
        $method->(
            $parser->{grammar},
            $parser,
            $parser->{buffer},
            $parser->{position},
        );
    }
}

sub make_trace_wrapper {
    my ($self, $method) = @_;
    return sub {
        my ($self, $ref, $parent) = @_;
        my $asr = $parent->{'+asr'};
        my $note =
            $asr == -1 ? '(!)' :
            $asr == 1 ? '(=)' :
            '';
        $self->trace("try_$ref$note");
        my $result;
        if ($result = $self->$method($ref, $parent)) {
            $self->trace("got_$ref$note");
        }
        else {
            $self->trace("not_$ref$note");
        }
        return $result;
    }
}

sub set_max_parse {
    require Pegex::Parser;
    my ($self) = @_;
    my $maxparse = $self->parser->{maxparse};
    no warnings 'redefine';
    my $method = \&Pegex::Parser::match_ref;
    my $counter = 0;
    *Pegex::Parser::match_ref = sub {
        die "Maximum parsing rules reached ($maxparse)\n"
            if $counter++ >= $maxparse;
        my $self = shift;
        $self->$method(@_);
    };
}

1;
