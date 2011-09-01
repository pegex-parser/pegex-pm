##
# name:      Pegex::Input
# abstract:  Pegex Parser Input Abstraction
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Input;
use Pegex::Base -base;

has 'string';
has 'stringref';
has 'file';
has 'handle';
# has 'http';
has '_buffer' => do { my $x; \$x };
has '_is_eof' => 0;
has '_is_open' => 0;
has '_is_close' => 0;
# has '_pos' => 0;
# has 'maxsize' => 4096;
# has 'minlines' => 2;

# NOTE: Current implementation reads entire input into _buffer on open().
sub read {
    my ($self) = @_;
    die "Attempted Pegex::Input::read before open" if not $self->_is_open;
    die "Attempted Pegex::Input::read after EOF" if $self->_is_eof;
    
    my $buffer = $self->_buffer;
    $self->_buffer(undef);
    $self->_is_eof(1);

    return $$buffer;
}

sub open {
    my $self = shift;
    die "Pegex::Input::open takes zero or one arguments"
        if @_ > 1;
    die "Attempted to reopen Pegex::Input object" if $self->_is_close;

    $self->_guess_input(@_) if @_;

    if (my $ref = $self->stringref) {
        $self->_buffer($ref);
    }
    elsif (my $handle = $self->handle) {
        $self->_buffer(\ do { local $/; <$handle> });
    }
    elsif (my $path = $self->file) {
        open my $handle, $path
            or die "Pegex::Input can't open $path for input:\n$!";
        $self->_buffer(\ do { local $/; <$handle> });
    }
    elsif (exists $self->{string}) {
        $self->_buffer(\$self->{string});
    }
    else {
        die "Pegex::open failed. No source to open";
    }

    $self->_is_open(1);

    return $self;
}

sub close {
    my ($self) = @_;
    die "Attempted to close an unopen Pegex::Input object" if $self->_is_close;
    close $self->handle if $self->handle;
    $self->_is_open(0);
    $self->_is_close(1);
    $self->_buffer(undef);
    return $self;
}

sub _guess_input {
    my ($self, $input) = @_;
    if (my $ref = ref($input)) {
        if ($ref eq 'SCALAR') {
            $self->stringref($ref);
        }
        else {
            $self->handle($ref);
        }
    }
    else {
        if (length($input) and ($input !~ /\n/) and -f $input) {
            $self->file($input);
        }
        else {
            $self->stringref(\$input);
        }
    }
}

1;

=head1 SYNOPSIS

This:

    use Pegex;
    use Pegex::Input;
    my $ast = pegex(Pegex::Input->new(file => 'foo-grammar-file.pgx')->open)
        ->parse(Pegex::Input->new(string => $foo_input)->open);

is the long way to do this:

    use Pegex;
    my $ast = pegex('foo-grammar-file.pgx')->parse($foo_input);

=head1 DESCRIPTION

Pegex::Parser parses input. The input can be a string, a string reference, a
file path, or an open file handle. Pegex::Input is an abstraction over any
type of input. It provides a uniform inteface to the parser.

It also give the end user total control, when it is needed. In the rare case
when you need to have Pegex parse a string that happens to be a filename,
you'll need to use a Pegex::Input object.
