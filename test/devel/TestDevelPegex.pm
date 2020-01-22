package TestDevelPegex;
use strict; use warnings;

use File::Spec;
use Test::More;
use IO::All;
use Time::HiRes qw(gettimeofday tv_interval);

my $time;

use base 'Exporter';
our @EXPORT = qw(
    pegex_parser
    pegex_parser_ast
    slurp
    test_grammar_paths
    gettimeofday
    tv_interval
    XXX
);

use constant TEST_GRAMMARS => [
    '../pegex-pgx/pegex.pgx',
    '../testml-pgx/testml.pgx',
    '../json-pgx/json.pgx',
    '../yaml-pgx/yaml.pgx',
    '../kwim-pgx/kwim.pgx',
    '../drinkup/share/drinkup.pgx',
    # '../SQL-Parser-Neo/pegex/pg-lexer.pgx',
    '../SQL-Parser-Neo/pegex/Pg.pgx',
];

sub pegex_parser {
    require Pegex::Parser;
    require Pegex::Pegex::Grammar;
    require Pegex::Tree::Wrap;
    my ($grammar) = @_;
    return Pegex::Parser->new(
        grammar => Pegex::Pegex::Grammar->new,
        receiver => Pegex::Tree::Wrap->new,
    );
}

sub pegex_parser_ast {
    require Pegex::Parser;
    require Pegex::Pegex::Grammar;
    require Pegex::Pegex::AST;
    my ($grammar) = @_;
    return Pegex::Parser->new(
        grammar => Pegex::Pegex::Grammar->new,
        receiver => Pegex::Pegex::AST->new,
    );
}

sub slurp {
    my ($path) = @_;
    return scalar io->file($path)->all;
}

sub test_grammar_paths {
    my @paths;
    for my $grammar_source (@{TEST_GRAMMARS()}) {
        my $grammar_file = check_grammar($grammar_source)
            or next;
        push @paths, $grammar_file;
    }
    return @paths;
}

#-----------------------------------------------------------------------------#
sub check_grammar {
    my ($source) = @_;
    (my $file = $source) =~ s!.*/!!;
    my $xt = -e 'xt' ? 'xt' : File::Spec->catfile('test', 'devel');
    my $path = File::Spec->catfile('.', $xt, 'grammars', $file);
    if (-e $source) {
        if (not -e $path) {
            diag "$path not found. Copying from $source\n";
            copy_grammar($source, $path);
        }
        elsif (slurp($source) ne slurp($path)) {
            diag "$path is out of date. Copying from $source\n";
            copy_grammar($source, $path);
        }
    }
    return -e $path ? $path : undef;
}

sub copy_grammar {
    my ($source, $target) = @_;
    return unless -e $source;
    io->file($target)->assert->print(slurp($source));
}

END {
    done_testing;
}

1;
