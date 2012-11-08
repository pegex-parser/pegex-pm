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
has receiver_class => 'Pegex::Tree';

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

=head1 SYNOPSIS

    package MyLanguage;
    use Pegex::Base;
    extends 'Pegex::Module';

    has grammar => 'MyLanguage::Grammar';
    has receiver => 'MyLanguage::AST';

    1;

=head1 DESCRIPTION

The module in the SYNOPSIS above is a complete language parsing module. It just
inherits from L<Pegex::Module>, and then overrides the C<grammar> and
C<receiver> properties. L<Pegex::Module> provides the C<parse()> method.
