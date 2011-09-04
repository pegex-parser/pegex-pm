##
# name:      Pegex::AST
# abstract:  Pegex Abstract Syntax Tree Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST2;
use Pegex::Receiver -base;

has 'parser';
has regex_map => {};
has add_full_regex_match => 0;
has keep_positions => 0;
has keep_empty_regex => 0;
has keep_empty_list => 0;
has keep_single_list => 0;

sub __final__ {
    my $self = shift;
    my $match = shift;
    $match = {} if ref($match) eq 'IGNORE ME';
    $self->data($match);
}

sub got {
    my ($self, $rule, $match) = @_;
    my $value = $self->prepare($match) or return;
    return +{
        $rule => $value,
    };
}

sub prepare {
    my ($self, $match) = @_;
    my $ref = ref($match) or die '$match is not a ref';
    return $match if ref($match) eq 'HASH';
    return if $ref eq 'IGNORE ME';
    return $self->prepare_array($match) if $ref eq 'ARRAY';
    XXX $match;
}

sub prepare_array {
    my ($self, $array) = @_;
    return $array if $self->regex_map->{$array};
    if (@$array and not(ref $array->[0])) {
        splice(@$array, 0, 2) unless $self->keep_positions;
        return if @$array == 0;
        if (@$array == 1) {
            $array = $array->[0];
        }
        else {
            $self->regex_map->{$array} = 1;
        }
        return $array;
    }
    my @value = (
        map {
            (ref($_) eq 'ARRAY') ? $self->prepare_array($_) : $_
        } @$array
    );
    return unless @value;
    return $value[0] if @value == 1;
    return \@value;
}

1;
