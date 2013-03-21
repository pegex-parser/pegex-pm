package TestAST;
use Pegex::Base;
extends 'Pegex::Tree';

sub got_zero { return 0 };
sub got_empty { return '' };
sub got_undef { return undef }

1;
