#!/usr/bin/env perl

# This is an example Pegex parser that parses itself! Each word is captured and
# uppercased, then added to the tree.
#
# This is a good script to start with to try new ideas, as it is
# self-contained.
use Pegex::Parser;
use FindBin '$Script';
use IO::All;
use YAML::PP;

# Pegex parsing needs:
#
# * A parser object
# * A grammar object
# * A receiver object
# * Some input to parse
#
# Try the debug option to see everything in detail.
sub main {
    my $parser = Pegex::Parser->new(
        grammar => SelfGrammar->new,
        receiver => SelfTree->new,
        debug => 1,
    );
    my $input = io->file($Script)->all;
    my $tree = $parser->parse($input);
    print YAML::PP::Dump $tree;
}

# A custom grammar class:
{
    package SelfGrammar;
    use Pegex::Base;
    extends 'Pegex::Grammar';

    use constant text => <<'...';
self: word* %% +

word: / ( NS+ ) /
...
}

# A custom receiver class:
{
    package SelfTree;
    use Pegex::Base;
    extends 'Pegex::Tree';

    sub got_word {
        my ($self, $got) = @_;
        uc $got;
    }
}

main(@ARGV);
