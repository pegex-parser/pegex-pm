package Pegex::Compiler;

use Pegex::Base;

use Pegex::Parser;
use Pegex::Pegex::Grammar;
use Pegex::Pegex::AST;
use Pegex::Grammar::Atoms;

has tree => ();

sub compile {
    my ($self, $grammar, @rules) = @_;

    # Global request to use the Pegex bootstrap compiler
    if ($Pegex::Bootstrap) {
        require Pegex::Bootstrap;
        $self = Pegex::Bootstrap->new;
    }

    @rules = map { s/-/_/g; $_ } @rules;

    $self->parse($grammar);
    $self->combinate(@rules);
    $self->native;

    return $self;
}

sub parse {
    my ($self, $input) = @_;

    my $parser = Pegex::Parser->new(
        grammar => Pegex::Pegex::Grammar->new,
        receiver => Pegex::Pegex::AST->new,
    );

    $self->{tree} = $parser->parse($input);

    return $self;
}

#-----------------------------------------------------------------------------#
# Combination
#-----------------------------------------------------------------------------#
has _tree => ();

sub combinate {
    my ($self, @rule) = @_;
    if (not @rule) {
        if (my $rule = $self->{tree}->{'+toprule'}) {
            @rule = ($rule);
        }
        else {
            return $self;
        }
    }
    $self->{_tree} = {
        map {($_, $self->{tree}->{$_})} grep { /^\+/ } keys %{$self->{tree}}
    };
    for my $rule (@rule) {
        $self->combinate_rule($rule);
    }
    $self->{tree} = $self->{_tree};
    delete $self->{_tree};
    return $self;
}

sub combinate_rule {
    my ($self, $rule) = @_;
    return if exists $self->{_tree}->{$rule};

    my $object = $self->{_tree}->{$rule} = $self->{tree}->{$rule};
    $self->combinate_object($object);
}

sub combinate_object {
    my ($self, $object) = @_;
    if (exists $object->{'.rgx'}) {
        $self->combinate_re($object);
    }
    elsif (exists $object->{'.ref'}) {
        my $rule = $object->{'.ref'};
        if (exists $self->{tree}{$rule}) {
            $self->combinate_rule($rule);
        }
        else {
            if (my $regex = (Pegex::Grammar::Atoms::atoms)->{$rule}) {
                $self->{tree}{$rule} = { '.rgx' => $regex };
                $self->combinate_rule($rule);
            }
        }
    }
    elsif (exists $object->{'.any'}) {
        for my $elem (@{$object->{'.any'}}) {
            $self->combinate_object($elem);
        }
    }
    elsif (exists $object->{'.all' }) {
        for my $elem (@{$object->{'.all'}}) {
            $self->combinate_object($elem);
        }
    }
    elsif (exists $object->{'.err' }) {
    }
    else {
        require YAML::XS;
        die "Can't combinate:\n" . YAML::XS::Dump($object);
    }
}

sub combinate_re {
    my ($self, $regexp) = @_;
    my $atoms = Pegex::Grammar::Atoms->atoms;
    my $re = $regexp->{'.rgx'};
    while (1) {
        $re =~ s[(?<!\\)(~+)]['<ws' . length($1) . '>']ge;
        $re =~ s[<([\w\-]+)>][
            (my $key = $1) =~ s/-/_/g;
            $self->{tree}->{$key} and (
                $self->{tree}->{$key}{'.rgx'} or
                die "'$key' not defined as a single RE"
            )
            or $atoms->{$key}
            or die "'$key' not defined in the grammar"
        ]e;
        last if $re eq $regexp->{'.rgx'};
        $regexp->{'.rgx'} = $re;
    }
}

#-----------------------------------------------------------------------------#
# Compile to native Perl regexes
#-----------------------------------------------------------------------------#
sub native {
    my ($self) = @_;
    $self->perl_regexes($self->{tree});
    return $self;
}

sub perl_regexes {
    my ($self, $node) = @_;
    if (ref($node) eq 'HASH') {
        if (exists $node->{'.rgx'}) {
            my $re = $node->{'.rgx'};
            $node->{'.rgx'} = qr/\G$re/;
        }
        else {
            for (keys %$node) {
                $self->perl_regexes($node->{$_});
            }
        }
    }
    elsif (ref($node) eq 'ARRAY') {
        $self->perl_regexes($_) for @$node;
    }
}

#-----------------------------------------------------------------------------#
# Serialization formatter methods
#-----------------------------------------------------------------------------#
sub to_yaml {
    require YAML::XS;
    my $self = shift;
    return YAML::XS::Dump($self->tree);
}

sub to_json {
    require JSON::XS;
    my $self = shift;
    return JSON::XS->new->utf8->canonical->pretty->encode($self->tree);
}

sub to_perl {
    my $self = shift;
    require Data::Dumper;
    no warnings 'once';
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Sortkeys = 1;
    my $perl = Data::Dumper::Dumper($self->tree);
    $perl =~ s/\?\^:/?-xism:/g;
    $perl =~ s!(\.rgx.*?qr/)\(\?-xism:(.*)\)(?=/)!$1$2!g;
    die "to_perl failed with non compatible regex in:\n$perl"
        if $perl =~ /\?\^/;
    return $perl;
}

1;
