##
# name:      Pegex::Receiver
# abstract:  Pegex Receiver Base Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011, 2012
# see:
# - Pegex::Tree
# - Pegex::Tree::Wrap
# - Pegex::Pegex::AST

package Pegex::Receiver;
use Pegex::Base;

has parser => (); # The parser object.

# Flatten a structure of nested arrays into a single array in place.
sub flatten {
    my ($self, $array, $times) = @_;
    $times //= -1;
    while ($times-- and grep {ref($_) eq 'ARRAY'} @$array) {
        @$array = map {
            (ref($_) eq 'ARRAY') ? @$_ : $_
        } @$array;
    }
    return $array;
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
        my ($self, $got) = @_;
        return $result;
    }

    # Pre-process
    sub initial { ... }

    # Post-process
    sub final {
        ...;
        return $final_result;
    }

=head1 DESCRIPTION

In Pegex, a B<receiver> is the class object that a B<parser> passes captured
data to when a B<rule> in a B<grammar> matches a part of an B<input> stream. A
receiver provides B<action methods> to turn parsed data into what the parser is
intended to do.

This is the base class of all Pegex receiver classes.

It doesn't do much of anything, which is the correct thing to do. If you use
this class as your receiver if won't do any extra work. See L<Pegex::Tree> for
a receiver base class that will help organize your matches by default.

=head2 How A Receiver Works

A Pegex grammar is made up of B<named-rules>, B<regexes>, and B<groups>. When a
B<regex> matches, the parser makes array of its capture strings. When a
B<group> matches, the parser makes an array of all the submatch arrays. In this
way a B<parse tree> forms.

When a B<named-rule> matches, an action method is called in the receiver class.
The method is passed the current B<parse tree> and returns what parser will
consider the new parse tree.

This makes for a very elegant and understandable API.

=head1 API

This section documents the methods that you can include in receiver subclass.

=over

=item C<got_$rulename($got)>

An action method for a specific, named rule.

    sub got_rule42 {
        my ($self, $got) = @_;
        ...
        return $result;
    }

The C<$got> value that is passed in is the current value of the parse tree.
What gets returned is whatever you want to new value to be.

=item C<gotrule($got)>

The action method for a named rule that does not have a specific action method.

=item C<initial()>

Called at the beginning of a parse operation, before the parsing begins.

=item C<final($got)>

Called at the end of a parse operation. Whatever this action returns, will be
the result of the parse.

=back

=head2 Methods

=over

=item C<parser>

An attribute containing the parser object that is currently running. This can
be very useful to introspect what is happening, and possibly modify the grammar
on the fly. (Experts only!)

=item C<flatten($array)>

A utility method that can turn an array of arrays into a single array. For
example:

    $self->flatten([1, [2, [3, 4], 5], 6]);
    # produces [1, 2, 3, 4, 5, 6]

Hashes are left unchanged. The array is modified in place, but is
also the reutrn value.

=back
