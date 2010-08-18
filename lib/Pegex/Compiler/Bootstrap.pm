package Pegex::Compiler::Bootstrap;
use Pegex::Compiler -base;

sub compile {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $grammar_text = shift;
    $self->grammar({});
    $grammar_text =~ s/^#.*\n+//gm;
    $grammar_text .= "\n" unless $grammar_text =~ /\n\z/;
    $grammar_text =~ s/;/\n/g;
    for my $rule (split /(?=^\w+:\s*)/m, $grammar_text) {
        (my $value = $rule) =~ s/^(\w+):// or die;
        my $key = $1;
        $value =~ s/\s+/ /g;
        $value =~ s/^\s*(.*?)\s*$/$1/;
        $self->grammar->{$key} = $value;
        $self->grammar->{_FIRST_RULE} ||= $key;
    }

    for my $rule (sort keys %{$self->grammar}) {
        next if $rule =~ /^_/;
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
    return $self;
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

1;
