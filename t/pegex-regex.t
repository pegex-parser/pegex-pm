use Test::More tests => 1;

use Pegex::Regex;

if ("xxxyyy" =~ qr{a: <b> <c>; b: /xxx/; c: /(yyy)/}) {
    is $/{a}{c}, 'yyy', 'Pegex::Regex works';
}
else {
    fail 'Pegex::Regex fails';
}
