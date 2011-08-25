##
# name:      Pegex::Compiler
# abstract:  Pegex Compiler
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler;
use Pegex::Base -base;
 
# has 'grammar';
# has 'grammar_file';
has 'tree';
has 'debug' => 0;

my $atoms;

sub compile {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $grammar_text = shift;

    $self->parse($grammar_text);
    $self->combinate;
    return $self;
}

sub compile_file {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $file = shift;
    open IN, $file or die "Can't open '$file'";
    my $grammar_text = do {local $/; <IN>};
    return $self->compile($grammar_text);
}

sub parse {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $grammar_text = shift;
    $self->tree({});

    require Pegex::Grammar::Pegex;
    my $grammar = Pegex::Grammar::Pegex->new(
        receiver => 'Pegex::Compiler::AST',
        debug => $self->debug,
    );

    my $tree = $grammar->parse($grammar_text);
    $self->tree($tree);

    return $self;
}

#------------------------------------------------------------------------------#
# Combination
#------------------------------------------------------------------------------#
has '_tree';

sub combinate {
    my $self = shift;
    my $rule = shift || $self->tree->{_FIRST_RULE};
    $self->_tree({
        map {($_, $self->tree->{$_})} grep { /^_/ } keys %{$self->tree}
    });
    $self->combinate_rule($rule);
    $self->tree($self->_tree);
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
    if (exists $object->{'+re'}) {
        $self->combinate_re($object);
    }
    elsif (exists $object->{'+rule'}) {
        my $rule = $object->{'+rule'};
        if (exists $self->tree->{$rule}) {
            $self->combinate_rule($rule);
        }
    }
    elsif (exists $object->{'+not'}) {
        my $rule = $object->{'+not'};
        if (exists $self->tree->{$rule}) {
            $self->combinate_rule($rule);
        }
    }
    elsif (exists $object->{'+any'}) {
        for my $elem (@{$object->{'+any'}}) {
            $self->combinate_object($elem);
        }
    }
    elsif (exists $object->{'+all' }) {
        for my $elem (@{$object->{'+all'}}) {
            $self->combinate_object($elem);
        }
    }
    elsif (exists $object->{'+error' }) {
    }
    else {
        require YAML::XS;
        die "Can't combinate:\n" . YAML::XS::Dump($object);
    }
}

sub combinate_re {
    my $self = shift;
    my $regexp = shift;
    while (1) {
        my $re = $regexp->{'+re'};
        $re =~ s[<(\w+)>][
            $self->tree->{$1} and
            $self->tree->{$1}{'+re'}
                or $atoms->{$1}
                or die "'$1' not defined in the grammar"
        ]e;
        last if $re eq $regexp->{'+re'};
        $regexp->{'+re'} = $re;
    }
}

#------------------------------------------------------------------------------#
# Output formatter methods
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
    $self->perl_regexes($self->tree);
    require Data::Dumper;
    no warnings 'once';
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper($self->tree);
}

sub perl_regexes {
    my $self = shift;
    my $node = shift;
    if (ref($node) eq 'HASH') {
        if (exists $node->{'+re'}) {
            my $re = $node->{'+re'};
            $node->{'+re'} = qr/\G$re/;
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
# Pegex regex atoms for grammars
#------------------------------------------------------------------------------#
# XXX This should probably be moved to Pegex::Grammar::Atoms
$atoms = {
    ALWAYS  => '',
    NEVER   => '(?!)',
    ALL     => '[\s\S]',
    ANY     => '.',
    BLANK   => '[\ \t]',
    BLANKS  => '\ \t',
    SPACE   => ' ',
    TAB     => '\t',
    WS      => '\s',
    NS      => '\S',
    BREAK   => '\n',
    CR      => '\r',
    EOL     => '\r?\n',
    EOS     => '\z',
    ALPHA   => '[a-zA-Z]',
    LOWER   => '[a-z]',
    UPPER   => '[A-Z]',
    DIGIT   => '[0-9]',
    XDIGIT  => '[0-9a-fA-F]',
    ALNUM   => '[a-zA-Z0-9]',
    WORD    => '\w',

    SINGLE  => "'",
    DOUBLE  => '"',
    LPAREN  => '\(',
    RPAREN  => '\)',
    LCURLY  => '\{',
    RCURLY  => '\}',
    LSQUARE => '\[',
    RSQUARE => '\]',
    LANGLE  => '<',
    RANGLE  => '>',

    BANG    => '!',
    AT      => '\@',
    HASH    => '\#',
    DOLLAR  => '\$',
    PERCENT => '%',
    CARET   => '\^',
    AMP     => '&',
    STAR    => '\*',

    TILDE   => '~',
    GRAVE   => '`',
    UNDER   => '_',
    DASH    => '-',
    PLUS    => '\+',
    EQUAL   => '=',
    PIPE    => '\|',
    BACK    => '\\\\',
    COLON   => ':',
    SEMI    => ';',
    COMMA   => ',',
    DOT     => '\.',
    QMARK   => '\?',
    SLASH   => '/',
};

sub atoms { return $atoms }

1;

=head1 SYNOPSIS

    use Pegex::Compiler;
    my $grammar_text = '... grammar text ...';
    my $pegex_compiler = Pegex::Compiler->new();
    my $grammar_tree = $pegex_compiler->compile($grammar_text);

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

You can optionally, preset these values:

    grammar => $grammar_text,
    grammar_file => $grammar_file_path,

=item $grammar_tree = $compiler->compile($grammar_text);

Compile a grammar text into a grammar tree that can be used by a
Pegex::Parser. This method is calls the C<parse> and C<combinate> methods and
returns the resulting tree.

=item $grammar_tree = $compiler->compile_file($grammar_file_path);

This method calls compile with the grammar string it reads from the file you
give it. It returns the resulting tree.

=item $compiler->parse($grammar_text)

The first step of a C<compile> is C<parse>. This applies the Pegex language
grammar to your grammar text and produces an unoptimized tree.

This method returns C<$self> so you can chain it to other methods.

=item $compiler->combinate()

Before a Pegex grammar tree can be used to parse things, it needs to be
combinated. This process turns the regex tokens into real regexes. It also
combines some rules together and eliminates rules that are not needed or have
been combinated. The result is a Pegex grammar tree that can be used by a
Pegex Parser.

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
