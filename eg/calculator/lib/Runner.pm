package Runner;
use Mo;

has args => [];
has callback => ();

sub run {
    my ($self, $calc) = @_;
    $self->callback($calc);

    return $self->run_file if @{$self->{args}};

    while (1) {
        print "\nEnter an equation: ";
        my $expr = <> || '';
        chomp $expr;
        last unless length $expr;
        $self->calc($expr);
    }
}

sub run_file {
    my ($self) = @_;
    my $file = shift(@{$self->args});
    open IN, "<", $file or die "Can't open '$file' for input";
    while (<IN>) {
        next if /^(?:#|$)/;
        chomp;
        $self->calc($_);
    }
}

sub calc {
    my ($self, $expr) = @_;
    my $result = eval { $self->callback->($expr) };
    if ($@) {
        warn $@;
        return;
    }
    print "$expr = $result\n";

    # Double-check answer:
    $expr =~ s/\^/**/g;
    $expr =~ s/--/- -/g;
    my $want = eval $expr;
    print "  EXPECTED $want\n"
        if $result ne $want;
}

1;
