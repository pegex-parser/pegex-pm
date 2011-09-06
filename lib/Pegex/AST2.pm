##
# name:      Pegex::AST
# abstract:  Pegex Abstract Syntax Tree Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST2;
use Pegex::Receiver -base;

has add_full_regex_match => 0;
has keep_positions => 0;
has keep_empty_regex => 0;
has keep_empty_list => 0;
has keep_single_list => 0;

sub final {
    my ($self, $match, $top) = @_;
    my $final = $match eq $Pegex::Ignore
        ? { $top => {} }
        : $match;
    $self->data($final);
    return $final;
}

sub got {
    my ($self, $rule, $match) = @_;
    return +{
        $rule => $match,
    };
}

1;
