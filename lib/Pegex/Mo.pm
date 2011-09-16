##
# name:      Pegex::Mo
# abstract:  Mo Base Class for Pegex
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Mo;
use Mo;

sub import {
    my $p = caller;
    no strict 'refs';
    if (not defined &{$p.'::XXX'}) {
        *{$p.'::WWW'} = \&WWW;
        *{$p.'::XXX'} = \&XXX;
        *{$p.'::YYY'} = \&YYY;
        *{$p.'::ZZZ'} = \&ZZZ;
    }
    goto &Mo::import;
}

use constant XXX_skip => 1;
our $DumpModule = 'YAML::XS';
sub WWW { require XXX; local $XXX::DumpModule = $DumpModule; XXX::WWW(@_) }
sub XXX { require XXX; local $XXX::DumpModule = $DumpModule; XXX::XXX(@_) }
sub YYY { require XXX; local $XXX::DumpModule = $DumpModule; XXX::YYY(@_) }
sub ZZZ { require XXX; local $XXX::DumpModule = $DumpModule; XXX::ZZZ(@_) }
