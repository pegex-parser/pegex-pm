use strict;
package t::FakeTestML;
use Test::More;

use Exporter 'import';
use XXX;

my $data;
my $label = '$label';

our @EXPORT = qw'
    require_or_skip
    data
    label
    loop
    test
    assert_equal
    assert_match
    plan
    done_testing
';

sub require_or_skip {
    eval "use $_[0]; 1"
        or plan skip_all => "Test requires $_[0]";
}

sub data {
    if ($_[0] =~ /\n/) {
        $data = parse_tml($_[0]);
    }
    else {
        open my $input, '<', $_[0]
            or die "Can't open $_[0] for input";
        $data = parse_tml(do {local $/; <$input>});
    }
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
    evaluate($expr, $block);
}

sub assert_equal {
    my ($got, $want, $block) = @_;
    my $title = $label;
    $title =~ s/\$label/$block->{title}/;
    $title =~ s/\$BlockLabel/$block->{title}/;
    is $got, $want, $title;
}

sub is_match {
    die;
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
    push @args, $block if $func =~ /^assert_/;
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
    $string =~ s/^\s*\n//;
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
                my ($key, $value);
                if ($str =~ s/^---\ +(\w+):\ +(.*)\n// or
                    $str =~ s/^---\ +(\w+)\n(.*?)(?=^---|\z)//sm
                ) {
                    ($key, $value) = ($1, $2);
                }
                else {
                    die "Failed to parse FakeTestML string:\n$str";
                }
                $block->{points}{$key} = $value;
                if ($key =~ /^(ONLY|SKIP|LAST)$/) {
                    $block->{$key} ||= 1;
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
