use strict;
package t::FakeTestML;
use Test::More;

use Exporter 'import';
use XXX;

my $data;
my $label = '$label';

our @EXPORT = qw'require_or_skip data label loop test plan done_testing';

sub require_or_skip {
    eval "use $_[0]; 1"
        or plan skip_all => "Test requires $_[0]";
}

sub data {
    open my $input, '<', $_[0]
        or die "Can't open $_[0] for input";
    $data = parse_tml(do {local $/; <$input>});
}

sub label {
    $label = shift;
}

sub loop {
    my ($expr, $callback) = @_;
    $callback //= \&test;
    for my $block (@{get_blocks($expr)}) {
        $callback->($block, $expr);
    }
}

sub test {
    my ($block, $expr) = @_;
    ($block) = @{get_blocks($expr, [$block])};
    return unless $block;
    my ($left, $op, $right) = @$expr;
    die "Invalid operator '$op'" if $op ne '==';
    my $got = evaluate($left, $block);
    my $want = evaluate($right, $block);
    my $title = $label;
    $title =~ s/\$label/$block->{title}/;
    $title =~ s/\$BlockLabel/$block->{title}/;
    is $got, $want, $title;
}

sub evaluate {
    my ($expr, $block) = @_;
    $expr = ['', $expr] unless ref $expr;
    my $func = $expr->[0];
    my @args = map {
        ref($_) ? evaluate($_, $block) :
        /^\*(\w+)$/ ? $block->{points}->{$1} :
        $_;
    } @{$expr}[1..$#{$expr}];
    return $args[0] unless $func;
    no strict 'refs';
    return &{"main::$func"}(@args);
}

sub get_blocks {
    my ($expr, $blocks) = @_;
    $blocks //= $data;
    my @want = grep s/^\*//, flatten($expr);
    my @only = grep $_->{ONLY}, @$blocks;
    $blocks = \@only if @only;
    my $final = [];
OUTER:
    for my $block (@$blocks) {
        next if $block->{SKIP};
        for (@want) {
            next OUTER unless exists $block->{points}{$_};
        }
        push @$final, $block;
        last if $block->{LAST};
    }
    return $final;
}

sub parse_tml {
    my ($string) = @_;
    $string =~ s/^#.*\n//gm;
    $string =~ s/^\\//gm;
    my @blocks = map {
        s/\n+\z/\n/;
        $_;
    } grep $_,
    split /(^===.*?(?=^===|\z))/ms, $string;
    return [
        map {
            my $str = $_;
            my $block = {};
            $str =~ s/^===\ +(.*?)\ *\n// or die;
            $block->{title} = $1;
            while ($str) {
                if ($str =~ s/^---\ +(\w+):\ +(.*)\n//) {
                    $block->{points}{$1} = $2;
                }
                elsif ($str =~ s/^---\ +(\w+)\n(.*?)(?=^---|\z)//sm) {
                    my ($key, $value) = ($1, $2);
                    if ($key =~ /^(ONLY|SKIP|LAST)$/) {
                        $block->{$key} = 1;
                    }
                    else {
                        $block->{points}{$key} = $value;
                    }
                }
                else {
                    die "Failed to parse FakeTestML string:\n$str";
                }
            }
            $block;
        } @blocks
    ];
}

sub flatten {
    my @list = @_;
    while (grep ref, @list) {
        @list = map {ref($_) ? @$_ : $_} @list;
    }
    return @list;
}

1;
