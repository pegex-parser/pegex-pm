##
# name:      Pegex::Bootstrap
# abstract:  Bootstrapping Compiler for a Pegex Grammar
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Bootstrap;
use Pegex::Mo;
extends 'Pegex::Compiler';

use Pegex::Grammar::Atoms;

my $quantifier = qr{(?:[\?\*\+]|\d+(?:\+|\-\d+)?)};

sub parse {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $grammar_text = shift;
    if ($grammar_text !~ /[\n\:]/) {
        open IN, $grammar_text
            or die "Can't open file '$grammar_text' for input";
        $grammar_text = do {local $/; <IN>};
        close IN;
    }
    $self->tree({});
    $grammar_text =~ s/^#.*\n+//gm;
    $grammar_text =~ s/^\s*\n//;
    $grammar_text .= "\n" unless $grammar_text =~ /\n\z/;
    $grammar_text =~ s/;/\n/g;
    if ($grammar_text =~ s/\A((%\w+ +.*\n)+)//) {
        my $section = $1;
        my (%directives) = ($section =~ /%(\w+) +(.*?) *\n/g);
        for my $key (keys %directives) {
            $self->tree->{"+$key"} = $directives{$key};
        }
    }
    for my $rule (split /(?=^\w+:\s*)/m, $grammar_text) {
        (my $value = $rule) =~ s/^(\w+):// or die "$rule";
        my $key = $1;
        $value =~ s/\s+/ /g;
        $value =~ s/^\s*(.*?)\s*$/$1/;
        $self->tree->{$key} = $value;
        $self->tree->{'+top'} ||= $key;
        $self->tree->{'+top'} = $key if $key eq 'TOP';
    }

    for my $rule (sort keys %{$self->tree}) {
        next if $rule =~ /^\+/;
        my $text = $self->tree->{$rule};
        my @tokens = grep $_,
        ($text =~ m{(
            /[^/\n]*/ |
            %?%%? |
            [\!\=\-\+\.]?<\w+>$quantifier? |
            `[^`\n]*` |
            \| |
            [\!\=?\.]?\[ |
            \]$quantifier? |
        )}gx);
        die "No tokens found for rule <$rule> => '$text'"
            unless @tokens;
        unshift @tokens, '[';
        push @tokens, ']';
        my $tree = $self->make_tree(\@tokens);
        $self->tree->{$rule} = $self->compile_next($tree);  
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
        if ($token =~ /^[\!\=?\.]?[\[]/) {
            push @$stack, [];
        }
        push @{$stack->[-1]}, $token;
        if ($token =~ /^[\]]/) {
            my $branch = pop @$stack;
            push @{$stack->[-1]}, $self->wilt($branch);
        }
    }
    return $tree->[0];
}

sub wilt {
    my $self = shift;
    my $branch = shift;
    return $branch unless ref($branch) eq 'ARRAY';
    my $wilted = [];
    for (my $i = 0; $i < @$branch; $i++) {
        push @$wilted, ($branch->[$i] =~ /^%?%%?$/)
            ? [$branch->[$i], pop(@$wilted), $branch->[++$i]]
            : $branch->[$i];
    }
    return $wilted;
}

sub compile_next {
    my $self = shift;
    my $node = shift;
    my $unit = ref($node) ?
        $node->[0] =~ /^%?%%?$/
            ? $self->compile_sep($node) :
        $node->[2] eq '|'
            ? $self->compile_group($node, 'any')
            : $self->compile_group($node, 'all')
    :
        $node =~ m!/! ? $self->compile_re($node) :
        $node =~ m!<! ? $self->compile_rule($node) :
        $node =~ m!`! ? $self->compile_error($node) :
            XXX $node;

    while (defined $unit->{'.all'} and @{$unit->{'.all'}} == 1) {
        $unit = $unit->{'.all'}->[0];
    }
    return $unit;
}

my %prefixes = (
    '!' => ['+asr', -1],
    '=' => ['+asr', 1],
    '.' => '-skip',
    '-' => '-pass',
    '+' => '-wrap',
);

sub compile_sep {
    my $self = shift;
    my $node = shift;
    my $object = $self->compile_next($node->[1]);
    $object->{'.sep'} = $self->compile_next($node->[2]);
    $object->{'.sep'}{'+eok'} = 1 if $node->[0] =~ /^%?%%$/;
    $object->{'.sep'}{'+bok'} = 1 if $node->[0] eq '%%%';
    return $object;
}

sub compile_group {
    my $self = shift;
    my $node = shift;
    my $type = shift;
    die unless @$node > 2;
    my $object = {};
    if ($node->[0] =~ /^([\=\!\.\-\+])/) {
        my ($key, $val) = ($prefixes{$1}, 1);
        ($key, $val) = @$key if ref $key;
        $object->{$key} = $val;
    }
    if ($node->[-1] =~ /([\?\*\+])$/) {
        $self->set_quantity($object, $1);
    }
    shift @$node;
    pop @$node;
    if ($type eq 'any') {
        $object->{'.any'} = [
            map $self->compile_next($_), grep {$_ ne '|'} @$node
        ];
    }
    elsif ($type eq 'all') {
        $object->{'.all'} = [
            map $self->compile_next($_), @$node
        ];
    }
    return $object;
}

sub set_quantity {
    my ($self, $object, $quantifier) = @_;
    if ($quantifier eq '*') {
        $object->{'+min'} = 0;
    }
    elsif ($quantifier eq '+') {
        $object->{'+min'} = 1;
    }
    elsif ($quantifier eq '?') {
        $object->{'+max'} = 1;
    }
    elsif ($quantifier =~ /^(\d+)\+$/) {
        $object->{'+min'} = $1;
    }
    elsif ($quantifier =~ /^(\d+)\-(\d+)+$/) {
        $object->{'+min'} = $1;
        $object->{'+max'} = $2;
    }
    elsif ($quantifier =~ /^(\d+)$/) {
        $object->{'+min'} = $1;
        $object->{'+max'} = $1;
    }
    else { die "Invalid quantifier: '$quantifier'" }
}

sub compile_re {
    my $self = shift;
    my $node = shift;
    my $object = {};
    $node =~ s!^/(.*)/$!$1! or die $node;
    $object->{'.rgx'} = $node;
    return $object;
}

sub compile_rule {
    my $self = shift;
    my $node = shift;
    my $object = {};
    if ($node =~ s/^([\=\!\-\+\.])//) {
        my ($key, $val) = ($prefixes{$1}, 1);
        ($key, $val) = @$key if ref $key;
        $object->{$key} = $val;
    }
    if ($node =~ s/($quantifier)$//) {
        $self->set_quantity($object, $1);
    }
    $node =~ s!^<(.*)>$!$1! or XXX $node;
    $object->{'.ref'} = $node;
    if (defined(my $re = Pegex::Grammar::Atoms->atoms->{$node})) {
        $self->tree->{$node} ||= {'.rgx' => $re};
    }
    return $object;
}

sub compile_error {
    my $self = shift;
    my $node = shift;
    my $object = {};
    $node =~ s!^`(.*)`$!$1! or die $node;
    $object->{'.err'} = $node;
    return $object;
}

1;
