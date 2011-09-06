use Test::More tests => 2;

use Pegex::Regex;

if ("xxxyyy" =~ qr{a: <b> <c>; b: /xxx/; c: /(yyy)/}) {
    is ref(\%/), 'HASH', 'Pegex::Regex works';
}
else {
    diag $@;
    fail 'Pegex::Regex fails';
}

if ("3 blind mice\n" =~ qr{t/mice.pgx}) {
    pass 'Pegex::Regex works with file grammar';
}
else {
    diag $@;
    fail 'Pegex::Regex fails';
}
