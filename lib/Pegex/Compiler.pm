package Pegex::Compiler;
use Pegex::Base;

use Pegex::Parser;
use Pegex::Pegex::Grammar;
use Pegex::Pegex::AST;
use Pegex::Grammar::Atoms;

use constant DEBUG => $ENV{PERL_PEGEX_COMPILER_DEBUG};

sub _debug {
    my ($label, @data) = @_;
    print STDERR "$label: ";
    print STDERR _dumper_nice(@data > 1 ? \@data : $data[0]);
}

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
        if (my $rule = $self->{tree}{'+toprule'}) {
            @rule = ($rule);
        }
        else {
            return $self;
        }
    }
    my $tree = {
        map {($_, $self->{tree}{$_})} grep { /^\+/ } keys %{$self->{tree}}
    };
    DEBUG and _debug "combinate", $self->{tree}, $tree;
    for my $rule (@rule) {
        $tree = $self->combinate_rule($tree, $rule);
    }
    DEBUG and _debug "combinate DONE", $tree;
    $self->{tree} = $tree;
    return $self;
}

sub combinate_rule {
    my ($self, $tree, $rule) = @_;
    DEBUG and _debug "combinate_rule($rule)", $tree;
    return $tree if exists $tree->{$rule};

    my $object = $self->{tree}{$rule};
    $tree = { %$tree, $rule => $object };
    ($tree, $object) = $self->combinate_object($tree, $object);
    return { %$tree, $rule => $object };
}

sub _quote_literal_to_re {
    my ($got) = @_;
    $got =~ s/([^\w\`\%\:\<\/\,\=\;])/\\$1/g;
    return $got;
}

sub combinate_object {
    my ($self, $tree, $object) = @_;
    DEBUG and _debug "combinate_object", $tree, $object;
    if (exists $object->{'.lit'}) {
        $object = { %$object }; # no mutate
        $object->{'.rgx'} = _quote_literal_to_re(delete $object->{'.lit'});
    }
    if (exists $object->{'.rgx'}) {
        $object = { %$object, '.rgx' => $self->combinate_re($tree, $object->{'.rgx'}) };
    }
    elsif (exists $object->{'.ref'}) {
        my $rule = $object->{'.ref'};
        if (exists $self->{tree}{$rule}) {
            $tree = $self->combinate_rule($tree, $rule);
        }
        else {
            if (my $regex = (Pegex::Grammar::Atoms::atoms)->{$rule}) {
                $regex = $self->combinate_re($tree, $regex);
                $tree = { %$tree, $rule => { '.rgx' => $regex } };
            }
        }
    }
    elsif (exists $object->{'.any'}) {
        my @collection;
        for my $elem (@{$object->{'.any'}}) {
            ($tree, $elem) = $self->combinate_object($tree, $elem);
            push @collection, $elem;
        }
        $object = { %$object, '.any' => \@collection };
    }
    elsif (exists $object->{'.all' }) {
        my @collection;
        for my $elem (@{$object->{'.all'}}) {
            ($tree, $elem) = $self->combinate_object($tree, $elem);
            push @collection, $elem;
        }
        $object = { %$object, '.all' => \@collection };
    }
    elsif (exists $object->{'.rtr' }) {
        $object = { %$object }; # no mutate
        my $rtr = delete $object->{'.rtr'};
        my @collection;
        for my $elem (@$rtr) {
            if (ref $elem) {
                my $part;
                if (defined($part = $elem->{'.rgx'})) {
                    $elem = $part;
                }
                elsif (defined($part = $elem->{'.lit'})) {
                    $elem = _quote_literal_to_re($part);
                }
                elsif (defined($part = $elem->{'.ref'})) {
                    $elem = "<$part>";
                }
            }
            push @collection, $elem;
        }
        DEBUG and _debug "combinate_object rtr", \@collection;
        my $regex = join '', @collection;
        $regex =~ s{\(([ism]?\:|\=|\!|<[=!])}{(?$1}g;
        $regex = $self->combinate_re($tree, $regex);
        $object = { %$object, '.rgx' => $regex };
    }
    elsif (exists $object->{'.err' }) {
    }
    else {
        require YAML::PP;
        die "Can't combinate:\n" .
            YAML::PP->new(schema => ['Core', 'Perl'])->dump_string($object);
    }
    return ($tree, $object);
}

sub combinate_re {
    my ($self, $tree, $re) = @_;
    DEBUG and _debug "combinate_re", $tree, $re;
    my $atoms = Pegex::Grammar::Atoms->atoms;
    my $prev = $re;
    while (1) {
        DEBUG and _debug "combinate_re sofar($re)";
        $re =~ s[(?<!\\)(~+)]['<ws' . length($1) . '>']ge;
        $re =~ s[<([\w\-]+)>][
            (my $key = $1) =~ s/-/_/g;
            my ($object, $tmp);
            if ($object = $self->{tree}{$key}) {
                ($tree, $object) = $self->combinate_object($tree, $object);
                $tmp = $object->{'.rgx'};
            }
            elsif ($object = $tree->{$key}) {
                ($tree, $object) = $self->combinate_object($tree, $object);
                $tmp = $object->{'.rgx'};
            }
            elsif ($tmp = $atoms->{$key}) {
            }
            else {
                die "'$key' not defined in the grammar";
            }
            $tmp;
        ]e;
        last if $re eq $prev;
        $prev = $re;
    }
    return $re;
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
    require YAML::PP;
    my $self = shift;
    my $yaml = YAML::PP->new(schema => ['Core', 'Perl'])
                       ->dump_string($self->tree);
    $yaml =~ s/\n *(\[\]\n)/ $1/g; # Work around YAML::PP formatting issue
    return $yaml;
}

sub to_json {
    require JSON::PP;
    my $self = shift;
    return JSON::PP->new->utf8->canonical->pretty->encode($self->tree);
}

sub _dumper_nice {
    my ($data) = @_;
    require Data::Dumper;
    no warnings 'once';
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper($data);
}

sub to_perl {
    my $self = shift;
    my $perl = _dumper_nice($self->tree);
    $perl =~ s/\?\^u?:/?-xism:/g; # the "u" is perl 5.14-18 equiv of /u
    $perl =~ s!(\.rgx.*?qr/)\(\?-xism:(.*)\)(?=/)!$1$2!g;
    $perl =~ s!/u$!/!gm; # perl 5.20+ put /u, older perls don't understand
    die "to_perl failed with non compatible regex in:\n$perl"
        if $perl =~ /\?\^/;
    return $perl;
}

1;
