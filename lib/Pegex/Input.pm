package Pegex::Input;

use Pegex::Base;

has string => ();
has stringref => ();
has file => ();
has handle => ();
has _buffer => ();
has _is_eof => 0;
has _is_open => 0;
has _is_close => 0;

# NOTE: Current implementation reads entire input into _buffer on open().
sub read {
    my ($self) = @_;
    die "Attempted Pegex::Input::read before open" if not $self->{_is_open};
    die "Attempted Pegex::Input::read after EOF" if $self->{_is_eof};

    my $buffer = $self->{_buffer};
    $self->{_buffer} = undef;
    $self->{_is_eof} = 1;

    return $buffer;
}

sub open {
    my ($self) = @_;
    die "Attempted to reopen Pegex::Input object"
        if $self->{_is_open} or $self->{_is_close};

    if (my $ref = $self->{stringref}) {
        $self->{_buffer} = $ref;
    }
    elsif (my $handle = $self->{handle}) {
        $self->{_buffer} = \ do { local $/; <$handle> };
    }
    elsif (my $path = $self->{file}) {
        open my $handle, $path
            or die "Pegex::Input can't open $path for input:\n$!";
        $self->{_buffer} = \ do { local $/; <$handle> };
    }
    elsif (exists $self->{string}) {
        $self->{_buffer} = \$self->{string};
    }
    else {
        die "Pegex::Input::open failed. No source to open";
    }
    $self->{_is_open} = 1;
    return $self;
}

sub close {
    my ($self) = @_;
    die "Attempted to close an unopen Pegex::Input object"
        if $self->{_is_close};
    close $self->{handle} if $self->{handle};
    $self->{_is_open} = 0;
    $self->{_is_close} = 1;
    $self->{_buffer} = undef;
    return $self;
}

1;
