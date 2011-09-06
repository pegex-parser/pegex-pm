##
# name:      Pegex::Compiler
# abstract:  Pegex Compiler
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler2;
use Pegex::Compiler -base;
 
use Pegex::Parser2;
use Pegex::Grammar::Pegex;
use Pegex::Compiler::AST2;
use Pegex::Grammar::Atoms;

sub parse {
    my $self = shift;
    $self = $self->new unless ref $self;

    my $parser = Pegex::Parser2->new(
        grammar => Pegex::Grammar::Pegex->new,
        receiver => Pegex::Compiler::AST2->new,
    );

    $self->tree($parser->parse(@_));

    return $self;
}

1;
