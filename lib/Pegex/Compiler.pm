##
# name:      Pegex::Compiler
# abstract:  Pegex Compiler
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler;
use Pegex::Mo;
 
use Pegex::Parser;
use Pegex::Pegex::Grammar;
use Pegex::Pegex::AST;
use Pegex::Grammar::Atoms;

has 'tree';

sub compile {
    my $self = shift;
    $self = $self->new unless ref $self;

    $self->parse(shift);
    $self->combinate;
    $self->perlify;

    return $self;
}

sub parse {
    if ($Pegex::Bootstrap) {
        require Pegex::Bootstrap;
        $_[0] = Pegex::Bootstrap->new;
        my $self = shift;
        return $self->parse(@_)
    }

    my $self = shift;
    $self = $self->new unless ref $self;

    my $parser = Pegex::Parser->new(
        grammar => Pegex::Pegex::Grammar->new,
        receiver => Pegex::Pegex::AST->new,
    );

    $self->tree($parser->parse(@_));

    return $self;
}

#------------------------------------------------------------------------------#
# Combination
#------------------------------------------------------------------------------#
has '_tree';

sub combinate {
    my $self = shift;
    my $rule = shift || $self->tree->{'+top'};
    $self->_tree({
        map {($_, $self->tree->{$_})} grep { /^\+/ } keys %{$self->tree}
    });
    $self->combinate_rule($rule);
    $self->tree($self->_tree);
    delete $self->{_tree};
    return $self;
}

sub combinate_rule {
    my $self = shift;
    my $rule = shift;
    return if exists $self->_tree->{$rule};

    my $object = $self->_tree->{$rule} = $self->tree->{$rule};
    $self->combinate_object($object);
}

sub combinate_object {
    my $self = shift;
    my $object = shift;
    if (my $sub = $object->{'.sep'}) {
        $self->combinate_object($sub);
    }
    if (exists $object->{'.rgx'}) {
        $self->combinate_re($object);
    }
    elsif (exists $object->{'.ref'}) {
        my $rule = $object->{'.ref'};
        if (exists $self->tree->{$rule}) {
            $self->combinate_rule($rule);
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
    my $self = shift;
    my $regexp = shift;
    my $atoms = Pegex::Grammar::Atoms->atoms;
    $regexp->{'.rgx'} =~ s!~!<ws>!g;
    my $re = $regexp->{'.rgx'};
    $re =~ s!~!<ws>!g;
    while (1) {
        $re =~ s[<(\w+)>][
            $self->tree->{$1} and
            $self->tree->{$1}{'.rgx'}
                or $atoms->{$1}
                or die "'$1' not defined in the grammar"
        ]e;
        last if $re eq $regexp->{'.rgx'};
        $regexp->{'.rgx'} = $re;
    }
}

#------------------------------------------------------------------------------#
# Perlify regexes
#------------------------------------------------------------------------------#
sub perlify {
    my $self = shift;
    $self->perl_regexes($self->tree);
    return $self;
}

sub perl_regexes {
    my $self = shift;
    my $node = shift;
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

#------------------------------------------------------------------------------#
# Serialization formatter methods
#------------------------------------------------------------------------------#
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
    return Data::Dumper::Dumper($self->tree);
}

1;

=head1 SYNOPSIS

    use Pegex::Compiler;
    my $grammar_text = '... grammar text ...';
    my $pegex_compiler = Pegex::Compiler->new();
    my $grammar_tree = $pegex_compiler->compile($grammar_text)->tree;

or:

    perl -Ilib -MYourGrammarModule=compile

=head1 DESCRIPTION

The Pegex::Compiler transforms a Pegex grammar string (or file) into a
compiled form. The compiled form is known as a grammar tree, which is simply a
nested data structure.

The grammar tree can be serialized to YAML, JSON, Perl, or any other
programming language. This makes it extremely portable. Pegex::Grammar has
methods for serializing to all these forms.

=head1 METHODS

The following public methods are available:

=over

=item $compiler = Pegex::Compiler->new();

Return a new Pegex::Compiler object.

=item $grammar_tree = $compiler->compile($grammar_input);

Compile a grammar text into a grammar tree that can be used by a
Pegex::Parser. This method is calls the C<parse> and C<combinate> methods and
returns the resulting tree.

Input can be a string, a string ref, a file path, a file handle, or a
Pegex::Input object. Return C<$self> so you can chain it to other methods.

=item $compiler->parse($grammar_text)

The first step of a C<compile> is C<parse>. This applies the Pegex language
grammar to your grammar text and produces an unoptimized tree.

This method returns C<$self> so you can chain it to other methods.

=item $compiler->combinate()

Before a Pegex grammar tree can be used to parse things, it needs to be
combinated. This process turns the regex tokens into real regexes. It also
combines some rules together and eliminates rules that are not needed or have
been combinated. The result is a Pegex grammar tree that can be used by a
Pegex::Parser.

NOTE: While the parse phase of a compile is always the same for various
programming langugaes, the combinate phase takes into consideration and
special needs of the target language. Pegex::Compiler only combinates for
Perl, although this is often sufficient in similar languages like Ruby or
Python (PCRE based regexes). Languages like Java probably need to use their
own combinators.

=item $compiler->tree()

Return the current state of the grammar tree (as a hash ref).

=item $compiler->to_yaml()

Serialize the current grammar tree to YAML.

=item $compiler->to_json()

Serialize the current grammar tree to JSON.

=item $compiler->to_perl()

Serialize the current grammar tree to Perl.

=back

=head1 IN PLACE COMPILATION

When you write a Pegex based module you will want to precompile your grammar
into Perl so that it has no load penalty. Pegex::Grammar provides a special
mechanism for this. Say you have a class like this:

    package MyThing::Grammar;
    use Pegex::Mo;
    extends 'Pegex::Grammar';

    use constant text => '../mything-grammar-repo/mything.pgx';
    sub tree {
    }

Simply use this command:

    perl -Ilib -MMyThing::Grammar=compile

and Pegex::Grammar will call Pegex::Compile to put your compiled grammar
inside your C<tree> subroutine. It will actually write the text into your
module. This makes it trivial to update your grammar module after making
changes to the grammar file.

See L<Pegex::JSON> for an example.
