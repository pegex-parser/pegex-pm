##
# name:      Pegex::AST
# abstract:  Pegex Abstract Syntax Tree Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::AST2;
use Pegex::Receiver -base;

sub __final__ {
    my $self = shift;
    my $match = shift;
    $self->data($match);
}

sub __got__ {
    my ($self, $kind, $rule, $match) = @_;
#     WWW [$kind, $rule, $match];
    my $ref = ref($match) or die '$match is not a ref';
    if (ref($match) eq 'HASH') {
        return +{
            $rule => $match,
        };
    }
    elsif ($ref eq 'ARRAY') {
        my $size = @$match;
        if ($size == 0) {
            return [];
        }
        if ($kind eq 'rgx') {
            if ($size == 1) {
                $match = $match->[0];
            }
            return +{
                $rule => $match,
            };
        }
        if ($kind =~ /^(?:all|any)$/) {
            return +{ $rule => [
                map {
                    (ref($_) eq 'ARRAY') ? (
                        (not @$_) ? () :
                        (@$_ == 1) ? $_->[0] : $_
                    ) : $_
                } @$match
            ]};
        }
        else {
            die "kind '$kind' not supported";
        }
    }
    else {
        XXX $match;
    }
}

1;
