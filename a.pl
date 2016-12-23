use strict;
use warnings;
use lib 'lib';
use Pegex;

open my $in, "a.pgx" or die $!;
my $grammar = do { local $/; <$in> };
close $in;

open $in, "a.in" or die $!;
my $input = do { local $/; <$in> };
close $in;

for ( 1 .. $ARGV[0] || 10) {
    pegex($grammar)->parse($input);
}
