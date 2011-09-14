##
# name:      Pegex::Module
# abstract:  Base Class for Pegex Grammar Interface Modules
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Module;
use Pegex::Mo;

sub parse {
    my ($self, $input) = @_;
    $self = $self->new unless ref $self;
    my $parser = $self->parser->new(
        grammar => $self->grammar,
        receiver => $self->receiver,
    );
    $parser->parse($input);
}

sub grammar {
    my ($self) = @_;
    $self = ref($self) || $self;
    my $class = "${self}::Grammar";
    eval "package $class; use base 'Pegex::Grammar'";
    return $class;
}

sub parser {
    my ($self) = @_;
    $self = ref($self) || $self;
    my $class = "${self}::Parser";
    eval "package $class; use base 'Pegex::Parser'";
    return $class;
}

sub receiver {
    my ($self) = @_;
    $self = ref($self) || $self;
    my $class = "${self}::Receiver";
    eval "package $class; use base 'Pegex::Receiver'";
    return $class;
}

1;
