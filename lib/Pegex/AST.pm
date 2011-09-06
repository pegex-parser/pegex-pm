##
# name:      Pegex::AST
# abstract:  Pegex Abstract Syntax Tree Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST;
use Pegex::Receiver -base;

# XXX Add these options.
# has add_full_regex_match => 0;
# has keep_positions => 0;
# has keep_empty_regex => 0;
# has keep_empty_list => 0;
# has keep_single_list => 0;

sub got {
    return +{ $_[1] => $_[2] };
}

sub final {
    my ($self, $match, $top) = @_;
    my $final = $match eq $Pegex::Ignore
        ? { $top => {} }
        : $match;
    $self->data($final);
    return $final;
}

1;
