##
# name:      Pegex::Receiver
# abstract:  Pegex Receiver Base Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011, 2012

package Pegex::Receiver;
use Pegex::Base;

# TODO Change name to 'got'
has data => ();
has got => ();

has parser => ();
has reference => ();
has parent => ();

# Flatten a structure of nested arrays into a single array.
# TODO Should be done in place.
sub flatten {
    my ($self, $array, $times) = @_;
    $times //= -1;
    return $array unless $times--;
    return [
        map {
            (ref($_) eq 'ARRAY') ? @{$self->flatten($_, $times)} : $_
        } @$array
    ];
}

1;

=head1 SYNOPSIS

    package MyReceiver;
    use base 'Pegex::Receiver';

    # Handle data for a specific rule
    sub got_somerulename {
        my ($self, $got) = @_;
        # ... process ...
        return $result;
    }

    # Handle data for any other rule
    sub gotrule {
        my ($self, $got, $name, $parent) = @_;
        return $result;
    }

    # Pre-process
    sub initial { ... }

    # Post-process
    sub final { ... }

=head1 DESCRIPTION

In Pegex, a B<receiver> is the class object that a B<parser> passes captured
data to as a B<rule> in a B<grammar> matches a part of an B<input> stream.

This is the base class of all Pegex receiver classes.

It doesn't do much of anything, which is the correct thing to do. If you use
this class as your receiver if won't do any extra work. See Pegex::AST for a
receiver base class that will help organize your matches by default.

=head1 API

This section documents the methods that you can include in receiver subclass.
This assumes that you are using the default parser L<Pegex::Parser>. Other
parser subclasses may honor more receiver methods.

=over

=item got

=item parser

=item got_$rulename

=item gotrule

=item initial

=item final

=back
