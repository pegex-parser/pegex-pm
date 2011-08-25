##
# name:      Pegex::Compiler
# abstract:  Pegex Compiler
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler;
use Pegex::Base -base;
 
# XXX Refactor:
# grammar means grammar_text
# tree means grammar_tree
has 'grammar';
has '_grammar';
has 'debug' => 0;

my $atoms;

# XXX this should return $self.
sub compile {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $grammar_text = shift;
    return $self->parse($grammar_text)->combinate->grammar;
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
    $self->grammar({});

    require Pegex::Compiler::Grammar;
    my $grammar = Pegex::Compiler::Grammar->new(
        receiver => $self,
        debug => $self->debug,
    );

    $grammar->parse($grammar_text);

    return $self;
}

#------------------------------------------------------------------------------#
# Combination
#------------------------------------------------------------------------------#
sub combinate {
    my $self = shift;
    my $rule = shift || $self->grammar->{_FIRST_RULE};
    $self->_grammar({
        map {($_, $self->grammar->{$_})} grep { /^_/ } keys %{$self->grammar}
    });
    $self->combinate_rule($rule);
    $self->grammar($self->_grammar);
    return $self;
}

sub combinate_rule {
    my $self = shift;
    my $rule = shift;
    return if exists $self->_grammar->{$rule};

    my $object = $self->_grammar->{$rule} = $self->grammar->{$rule};
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
        if (exists $self->grammar->{$rule}) {
            $self->combinate_rule($rule);
        }
    }
    elsif (exists $object->{'+not'}) {
        my $rule = $object->{'+not'};
        if (exists $self->grammar->{$rule}) {
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
            $self->grammar->{$1} and
            $self->grammar->{$1}{'+re'}
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
    return YAML::XS::Dump($self->grammar);
}

sub to_json {
    require JSON::XS;
    my $self = shift;
    return JSON::XS->new->utf8->canonical->pretty->encode($self->grammar);
}

sub to_perl {
    my $self = shift;
    $self->perl_regexes($self->grammar);
    require Data::Dumper;
    no warnings 'once';
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper($self->grammar);
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

#------------------------------------------------------------------------------#
# Receiver methods
#------------------------------------------------------------------------------#
# XXX This can be its own inline class
has 'stack' => [];

sub got_rule_name {
    my $self = shift;
    my $name = shift;
    $self->grammar->{_FIRST_RULE} ||= $name;
    push @{$self->stack}, [$name];
}

sub got_rule_definition {
    my $self = shift;
    $self->grammar->{$self->stack->[0]->[0]} = $self->stack->[0]->[1];
    $self->stack([]);
}

sub got_regular_expression {
    my $self = shift;
    my $re = shift;
    push @{$self->stack->[-1]}, {'+re' => $re};
}

sub try_any_group {
    my $self = shift;
    push @{$self->stack}, {'+any' => []};
}
sub not_any_group {
    my $self = shift;
    pop @{$self->stack};
}

sub try_all_group {
    my $self = shift;
    push @{$self->stack}, {'+all' => []};
}
sub not_all_group {
    my $self = shift;
    pop @{$self->stack};
}

sub got_rule_group {
    my $self = shift;
    my $group = pop @{$self->stack};
    push @{$self->stack->[-1]}, $group;
}

sub got_rule_reference {
    my $self = shift;
    my ($modifier, $name, $quantifier) = @_;
    my $rule =
        $modifier eq '!' ?
            { '+not' => $name } :
            { '+rule' => $name };
    $rule->{'<'} = $quantifier if $quantifier;
    my $current = $self->stack->[-1];
    # A single reference
    if (ref $current ne 'HASH') {
        push @{$self->stack->[-1]}, $rule;
    }
    # An 'all' group
    elsif ($current->{'+all'}) {
        push @{$current->{'+all'}}, $rule;
    }
    # An 'any' group
    elsif ($current->{'+any'}) {
        push @{$current->{'+any'}}, $rule;
    }
}

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
