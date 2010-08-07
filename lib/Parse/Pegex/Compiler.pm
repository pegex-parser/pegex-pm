package Parse::Pegex::Compiler;
use Parse::Pegex::Base -base;

has 'grammar';
has 'combined';

sub grammar_file_to_yaml {
    require YAML::XS;
    my $class = shift;
    my $file = shift;
    open IN, $file or die "Can't open '$file'";
    my $grammar = do {local $/; <IN>};
    return YAML::XS::Dump($class->new->compile($grammar));
}

my $atoms = {
    ALWAYS => '',
    ALL => '[\s\S]',
    ANY => '.',
    SPACE => '[\ \t]',
    SPACES => '\ \t',
    BREAK => '\n',
    EOL => '\r?\n',
    LOWER => '[a-z]',
    UPPER => '[A-Z]',
    WORD => '\w',
    DIGIT => '[0-9]',
    EQUAL => '=',
    TILDE => '~',
    PERCENT => '%',
    STAR => '\*',
    DASH => '-',
    DOT => '\.',
    COMMA => ',',
    COLON => ':',
    SEMI => ';',
    HASH => '#',
    BACK => '\\\\',
    SINGLE => "'",
    DOUBLE => '"',
    LPAREN => '\(',
    RPAREN => '\)',
    LSQUARE => '\[',
    LANGLE => '<',
};

sub compile {
    my $self = shift;
    my $grammar_text = shift;
    $self->grammar({});
    $grammar_text =~ s/^#.*\n//gm;
    my $first_rule;
    for my $rule (split /(?=^\w+:\s)/m, $grammar_text) {
        (my $value = $rule) =~ s/^(\w+):// or die;
        my $key = $1;
        $value =~ s/\s+/ /g;
        $value =~ s/^\s*(.*?)\s*$/$1/;
        $self->grammar->{$key} = $value;
        $first_rule ||= $key;
    }

    for my $rule (sort keys %{$self->grammar}) {
        my $text = $self->grammar->{$rule};
        my @tokens = ($text =~ m{(
            /[^/]*/ |
            <[\!\&]?\w+>[\?\*\+]? |
            `[^`]*` |
            \| |
            \[[\!\&?]? |
            \][\?\*\+]? |
            \([\!\&?]? |
            \)[\?\*\+]?
        )}gx);
        die "No tokens found for rule <$rule> => '$text'"
            unless @tokens;
        unshift @tokens, '[';
        push @tokens, ']';
        my $tree = $self->make_tree(\@tokens);
        $self->grammar->{$rule} = $self->compile_next($tree);  
    }
    $self->combinate($first_rule);
    return $self;
}

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
        die "Can't combinate: $object";
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

sub make_tree {
    my $self = shift;
    my $tokens = shift;
    my $stack = [];
    my $tree = [];
    push @$stack, $tree;
    for my $token (@$tokens) {
        if ($token =~ /^[\[\(]/) {
            push @$stack, [];
        }
        push @{$stack->[-1]}, $token;
        if ($token =~ /^[\]\)]/) {
            my $branch = pop @$stack;
            push @{$stack->[-1]}, $branch;
        }
    }
    return $tree->[0];
}

sub compile_next {
    my $self = shift;
    my $node = shift;
    my $unit = ref($node)
        ? $node->[2] eq '|'
            ? $self->compile_group($node, 'any')
            : $self->compile_group($node, 'all')
        : $node =~ m!/! ? $self->compile_re($node)
        : $node =~ m!<! ? $self->compile_rule($node)
        : $node =~ m!`! ? $self->compile_error($node)
        : die $node;

    while (defined $unit->{'+all'} and @{$unit->{'+all'}} == 1) {
        $unit = $unit->{'+all'}->[0];
    }
    return $unit;
}

sub compile_group {
    my $self = shift;
    my $node = shift;
    my $type = shift;
    die unless @$node > 2;
    if ($node->[0] =~ s/\&$//) {
        return $self->compile_has($node);
    }
    if ($node->[0] =~ s/\!$//) {
        return $self->compile_not($node);
    }
    my $object = {};
    if ($node->[-1] =~ /([\?\*\+])$/) {
        $object->{'<'} = $1;
    }
    shift @$node;
    pop @$node;
    if ($type eq 'any') {
        $object->{'+any'} = [
            map $self->compile_next($_), grep {$_ ne '|'} @$node
        ];
    }
    elsif ($type eq 'all') {
        $object->{'+all'} = [
            map $self->compile_next($_), @$node
        ];
    }
    return $object;
}

sub compile_re {
    my $self = shift;
    my $node = shift;
    my $object = {};
    $node =~ s!^/(.*)/$!$1! or die $node;
    $object->{'+re'} = $node;
    return $object;
}

sub compile_rule {
    my $self = shift;
    my $node = shift;
    my $object = {};
    if ($node =~ s/([\?\*\+])$//) {
        $object->{'<'} = $1;
    }
    $node =~ s!^<(.*)>$!$1! or die;
    if ($node =~ s/^!//) {
        $object->{'+not'} = $node;
    }
    else {
        $object->{'+rule'} = $node;
    }
    return $object;
}

sub compile_error {
    my $self = shift;
    my $node = shift;
    my $object = {};
    $node =~ s!^`(.*)`$!$1! or die $node;
    $object->{'+error'} = $node;
    return $object;
}

sub to_perl {
    my $self = shift;
    $self->compile_perl_regex($self->grammar);
    require Data::Dumper;
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

1;
