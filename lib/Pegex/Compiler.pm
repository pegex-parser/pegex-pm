package Pegex::Compiler;
use Pegex::Base -base;

has 'grammar';
has 'combined';

has 'first_rule';
has 'stack' => [];
has 'rule';

my $atoms;

use XXX;
sub compile {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $grammar_text = shift;
    $self->grammar({});

    require Pegex::Compiler::Grammar;
    my $grammar = Pegex::Compiler::Grammar->new(
        receiver => $self,
    );

    $grammar->parse($grammar_text);

    $self->combinate($self->first_rule);
    $self->grammar->{_FIRST_RULE} = $self->first_rule;

    return $self;
}

sub got_rule_name {
    my $self = shift;
    my $name = shift;
    $self->{first_rule} ||= $name;
    my $rule = $self->grammar->{$name} = {};
    push @{$self->stack}, $rule;
}

sub got_regular_expression {
    my $self = shift;
    $self->stack->[-1]->{'+re'} = shift;
}

# Combination
sub combinate {
    my $self = shift;
    my $rule = shift;
    $self->combined({});
    $self->combinate_rule($rule);
    $self->grammar($self->combined);
}

sub combinate_rule {
    my $self = shift;
    my $rule = shift;
    return if exists $self->combined->{$rule};

    my $object = $self->combined->{$rule} = $self->grammar->{$rule};
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

sub grammar_file_to_yaml {
    require YAML::XS;
    my $class = shift;
    my $file = shift;
    open IN, $file or die "Can't open '$file'";
    my $grammar = do {local $/; <IN>};
    return YAML::XS::Dump($class->new->compile($grammar)->grammar);
}

sub to_perl {
    my $self = shift;
#     use XXX;
#     XXX $self->grammar->{regular_expression};
#     print $self->grammar->{regular_expression}{'+re'}, "\n";
#     die;
    $self->compile_perl_regex($self->grammar);
    require Data::Dumper;
    no warnings 'once';
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper($self->grammar);
}

sub compile_perl_regex {
    my $self = shift;
    my $node = shift;
    if (ref($node) eq 'HASH') {
        if (exists $node->{'+re'}) {
            my $re = $node->{'+re'};
            $node->{'+re'} = qr/\G$re/;
        }
        else {
            for (keys %$node) {
                $self->compile_perl_regex($node->{$_});
            }
        }
    }
    elsif (ref($node) eq 'ARRAY') {
        $self->compile_perl_regex($_) for @$node;
    }
}

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
    BREAK   => '\n',
    CR      => '\r',
    EOL     => '\r?\n',
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
