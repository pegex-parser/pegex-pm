##
# name:      Pegex::Module
# abstract:  Base Class for Pegex Grammar Interface Modules
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011, 2012

package Pegex::Module;
use Pegex::Base;

has parser_class => 'Pegex::Parser';
has grammar_class => (
    default => sub {
        my $class = ref($_[0]);
        die "$class needs a 'grammar_class' property";
    },
);
has receiver_class => 'Pegex::Pegex::AST';

sub parse {
    my ($self, $input) = @_;
    $self = $self->new unless ref $self;
    my $parser = $self->parser_class->new(
        grammar => $self->grammar_class->new,
        receiver => $self->receiver_class->new,
    );
    $parser->parse($input);
}

1;
