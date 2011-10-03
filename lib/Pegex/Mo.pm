##
# name:      Pegex::Mo
# abstract:  Mo Base Class for Pegex
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Mo;
# use Mo qw[builder default xxx import];
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.25
no warnings;my$M=__PACKAGE__.::;*{$M.Object::new}=sub{bless{@_[1..$#_]},$_[0]};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.::;shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o)for@_;%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'builder::e'}=sub{my($P,$e,$o)=@_;$o->{builder}=sub{my($m,$n,%a)=@_;my$b=$a{builder}or return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$m->(@_)}}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;$a{default}or return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$a{default}->(@_):$m->(@_)}}};use constant XXX_skip=>1;${$M.'::DumpModule'}='YAML::XS';*{$M.'xxx::e'}=sub{my($P,$e)=@_;$e->{WWW}=sub{require XXX;local$XXX::DumpModule=${$M.DumpModule};XXX::WWW(@_)};$e->{XXX}=sub{require XXX;local$XXX::DumpModule=${$M.DumpModule};XXX::XXX(@_)};$e->{YYY}=sub{require XXX;local$XXX::DumpModule=${$M.DumpModule};XXX::YYY(@_)};$e->{ZZZ}=sub{require XXX;local$XXX::DumpModule=${$M.DumpModule};XXX::ZZZ(@_)}};my$i=\&import;*{$M.import}=sub{(@_==2 and not $_[1])?pop@_:@_==1        ?push@_,grep!/import/,@f:();goto&$i};@f=qw[builder default xxx import];

our $DumpModule = 'YAML';
