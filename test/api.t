use strict;
use warnings;

use Test::More;

use Pegex::Parser;
use Pegex::Grammar;
use Pegex::Receiver;
use Pegex::Input;

my $p = Pegex::Parser->new(
    grammar => Pegex::Grammar->new,
    receiver => Pegex::Receiver->new,
    input => Pegex::Input->new,
    debug => 1,
);

ok $p->grammar, 'grammar accessor works';
ok $p->receiver, 'receiver accessor works';
ok $p->input, 'input accessor works';
ok $p->debug, 'debug accessor works';

eval { Pegex::Parser->new };

ok $@ =~ /grammar required/, 'grammar is required';

done_testing;
