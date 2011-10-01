##
# name:      Pegex::Mo
# abstract:  Mo Base Class for Pegex
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Mo;
# use Mo qw[builder default];
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.25
no warnings;my$M=__PACKAGE__.::;*{$M.Object::new}=sub{bless{@_[1..$#_]},$_[0]};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.::;shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o)for@_;%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'builder::e'}=sub{my($P,$e,$o)=@_;$o->{builder}=sub{my($m,$n,%a)=@_;my$b=$a{builder}or return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$m->(@_)}}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;$a{default}or return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$a{default}->(@_):$m->(@_)}}};use strict;use warnings;

{
    no strict 'refs';
    no warnings 'redefine';

    my $import = \&{__PACKAGE__ . '::import'};
    *import = sub {
        my $p = caller;
        if (not defined &{$p.'::XXX'}) {
            *{$p.'::WWW'} = \&WWW;
            *{$p.'::XXX'} = \&XXX;
            *{$p.'::YYY'} = \&YYY;
            *{$p.'::ZZZ'} = \&ZZZ;
        }
        push @_, qw(builder default);
        goto &$import;
    };
}

use constant XXX_skip => 1;
our $DumpModule = 'YAML::XS';
sub WWW { require XXX; local $XXX::DumpModule = $DumpModule; XXX::WWW(@_) }
sub XXX { require XXX; local $XXX::DumpModule = $DumpModule; XXX::XXX(@_) }
sub YYY { require XXX; local $XXX::DumpModule = $DumpModule; XXX::YYY(@_) }
sub ZZZ { require XXX; local $XXX::DumpModule = $DumpModule; XXX::ZZZ(@_) }
