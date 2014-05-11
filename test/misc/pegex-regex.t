use Test::More tests => 1;

use Pegex::Regex;
use Data::Dumper;

if ("xxxyyy" =~ qr{a: <b> <c>; b: /xxx/; c: /(yyy)/}) {
    is ref(\%/), 'HASH', 'Pegex::Regex works';
}
else {
    diag $@;
    fail 'Pegex::Regex fails';
}
