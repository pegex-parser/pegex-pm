##
# name:      Pegex::Input
# abstract:  Pegex Parser Input Abstraction
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Input;
use Pegex::Mo;

has 'string';
has 'stringref';
has 'file';
has 'handle';
# has 'http';
has '_buffer' => default => sub { my $x; \$x };
has '_is_eof' => default => sub { 0 };
has '_is_open' => default => sub { 0 };
has '_is_close' => default => sub { 0 };
# has '_pos' => 0;
# has 'maxsize' => 4096;
# has 'minlines' => 2;

sub new {
    my $class = shift;
    die "Pegex::Input->new() requires one or 2 arguments"
        unless 1 <= @_ and @_ <= 2;
    my $method = @_ == 2 ? shift : $class->_guess_input(@_);
    return $class->SUPER::new($method => shift);
}

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
    die "Pegex::Input::open takes no arguments" if @_;
    die "Attempted to reopen Pegex::Input object"
        if $self->_is_open or $self->_is_close;

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
    return ref($_[1])
        ? (ref($_[1]) eq 'SCALAR')
            ? 'stringref'
            : 'handle'
        : (length($_[1]) and ($_[1] !~ /\n/) and -f $_[1])
            ? 'file'
            : 'string';
}

1;

=head1 SYNOPSIS

This:

    use Pegex;
    use Pegex::Input;
    my $ast = pegex(Pegex::Input->new(file => 'foo-grammar-file.pgx'))
        ->parse(Pegex::Input->new(string => $foo_input));

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

=head1 USAGE

There are 2 ways to create a Pegex::Input object. You can call new() with two
arguments, where the first argument is the input type:

    Pegex::Input->new(file => 'file.txt')

or you can call new() with no type specifier and let it guess.

    Pegex::Input->new($somesuch)

The second form is usually used internally when you call a Pegex facility,
like these:

    pegex($somesuch)->parse($someothersuch);
    Pegex::Grammar::Foo->parse($somefoo);

It is nice syntax to not need to specify the type when it is obvious.
Sometimes it is not obvious and you need to use Pegex::Input directly:

    pegex(Pegex::Input(file => $somesuch))
        ->parse(Pegex::Input->new(stringref => $someothersuch));
    Pegex::Grammar::Foo->parse(Pegex::Input->new(handle => $somefoo));

If you do specify the type, use one of these:

=over

=item string

Input is a string.

=item stringref

Input is a string reference. This may be desirable for really long strings.

=item file

Input is a file path name to be opened and read.

=item handle

Input is from a opened file handle, to be read.

=back
