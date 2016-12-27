package Pegex::Compiler;
use Pegex::Base;

use Pegex::Parser;
use Pegex::Pegex::Grammar;
use Pegex::Pegex::AST;
use Pegex::Grammar::Atoms;

has tree => ();
has parser => ();
has grammar => ();
has receiver => ();

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
# Grammar optimizations
#-----------------------------------------------------------------------------#
sub optimize_grammar {
    my ($self, $start) = @_;
    my $tree = $self->grammar->{tree};
    return if $tree->{'+optimized'};
    $self->set_max_parse if $self->parser->{maxparse};
    $self->{extra} = {};
    while (my ($name, $node) = each %$tree) {
        next unless ref($node);
        $self->optimize_node($node);
    }
    $self->optimize_node({'.ref' => $start});
    my $extra = delete $self->{extra};
    for my $key (%$extra) {
        $tree->{$key} = $extra->{$key};
    }
    $tree->{'+optimized'} = 1;
}

sub optimize_node {
    my ($self, $node) = @_;

    my ($min, $max) = @{$node}{'+min', '+max'};
    $node->{'+min'} = defined($max) ? 0 : 1
        unless defined $node->{'+min'};
    $node->{'+max'} = defined($min) ? 0 : 1
        unless defined $node->{'+max'};
    $node->{'+asr'} = 0
        unless defined $node->{'+asr'};

    for my $kind (qw(ref rgx all any err code xxx)) {
        return if $kind eq 'xxx';
        if ($node->{rule} = $node->{".$kind"}) {
            delete $node->{".$kind"};
            $node->{kind} = $kind;
            if ($kind eq 'ref') {
                my $rule = $node->{rule} or die;
                if (my $method = $self->grammar->can("rule_$rule")) {
                    $node->{method} = $self->make_method_wrapper($method);
                }
                elsif (not $self->grammar->{tree}{$rule}) {
                    if (my $method = $self->grammar->can("$rule")) {
                        warn <<"...";
Warning:

    You have a method called '$rule' in your grammar.
    It should probably be called 'rule_$rule'.

...
                    }
                    die "No rule '$rule' defined in grammar";
                }
            }
            $node->{method} ||= $self->parser->can("match_$kind") or die;
            last;
        }
    }

    if ($node->{kind} =~ /^(?:all|any)$/) {
        $self->optimize_node($_) for @{$node->{rule}};
    }
    elsif ($node->{kind} eq 'ref') {
        my $ref = $node->{rule};
        my $rule = $self->grammar->{tree}{$ref};
        $rule ||= $self->{extra}{$ref} = {};
        if (my $action = $self->receiver->can("got_$ref")) {
            $rule->{action} = $action;
        }
        elsif (my $gotrule = $self->receiver->can("gotrule")) {
            $rule->{action} = $gotrule;
        }
        if ($self->parser->{debug}) {
            $node->{method} = $self->make_trace_wrapper($node->{method});
        }
    }
    elsif ($node->{kind} eq 'rgx') {
      # XXX $node;
    }
}

sub make_method_wrapper {
    my ($self, $method) = @_;
    return sub {
        my ($parser, $ref, $parent) = @_;
        @{$parser}{'rule', 'parent'} = ($ref, $parent);
        $method->(
            $parser->{grammar},
            $parser,
            $parser->{buffer},
            $parser->{position},
        );
    }
}

sub make_trace_wrapper {
    my ($self, $method) = @_;
    return sub {
        my ($self, $ref, $parent) = @_;
        my $asr = $parent->{'+asr'};
        my $note =
            $asr == -1 ? '(!)' :
            $asr == 1 ? '(=)' :
            '';
        $self->trace("try_$ref$note");
        my $result;
        if ($result = $self->$method($ref, $parent)) {
            $self->trace("got_$ref$note");
        }
        else {
            $self->trace("not_$ref$note");
        }
        return $result;
    }
}

sub set_max_parse {
    require Pegex::Parser;
    my ($self) = @_;
    my $maxparse = $self->parser->{maxparse};
    no warnings 'redefine';
    my $method = \&Pegex::Parser::match_ref;
    my $counter = 0;
    *Pegex::Parser::match_ref = sub {
        die "Maximum parsing rules reached ($maxparse)\n"
            if $counter++ >= $maxparse;
        my $self = shift;
        $self->$method(@_);
    };
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
