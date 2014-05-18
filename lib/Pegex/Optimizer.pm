package Pegex::Optimizer;
use Pegex::Base;

has parser => (required => 1);
has grammar => (required => 1);
has receiver => (required => 1);

sub optimize_grammar {
    my ($self, $start) = @_;
    return if $self->grammar->tree->{optimized};
    while (my ($name, $node) = each %{$self->grammar->{tree}}) {
        next unless ref($node);
        $self->optimize_node($node);
    }
    $self->optimize_node({'.ref' => $start});
    $self->{optimized} = 1;
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
        die if $kind eq 'xxx';
        if ($node->{rule} = $node->{".$kind"}) {
            $node->{kind} = $kind;
            $node->{method} = $self->parser->can("match_$kind") or die;
            last;
        }
    }

    if ($node->{kind} =~ /^(?:all|any)$/) {
        $self->optimize_node($_) for @{$node->{rule}};
    }
    elsif ($node->{kind} eq 'ref') {
        my $ref = $node->{rule};
        my $rule = $self->grammar->{tree}{$ref};
        if (my $action = $self->receiver->can("got_$ref")) {
            $rule->{action} = $action;
        }
        elsif (my $gotrule = $self->receiver->can("gotrule")) {
            $rule->{action} = $gotrule;
        }
        $node->{method} = $self->parser->can("match_ref_trace")
            if $self->parser->{debug};
    }
    elsif ($node->{kind} eq 'rgx') {
      # XXX $node;
    }
}

1;
