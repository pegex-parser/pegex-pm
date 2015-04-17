use strict;use warnings;

use Pegex;
use Pegex::Grammar;
use Pegex::Tree::Wrap;

my ($grammar, $buffer);

END {
    Pegex::Parser->new(
        grammar => Pegex::Grammar->new( text => $grammar ),
        receiver => Pegex::Tree::Wrap->new(),
        debug => 0,
    )->parse($buffer);
}

$buffer = "*document here\n\n.lib mylib1\n" . (<<'...' x 500) . ".endl mylib1\n\n\n";  # 260
* comment
.subckt mysubckt1 d g s b a=1 b=2 c=3 d =4
+ x=1 y = 1 z =2
.param p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 p7=7 p8=8 p9=9 p10=10 p11=11 p12=12
+ p13=13 p14=14 p15=15 p16=16 p17=17 p18=18 p19=19 p20=20 p21=21 p22=22 p23=23 p24=24
.param p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 p7=7 p8=8 p9=9 p10=10 p11=11 p12=12
+ p13=13 p14=14 p15=15 p16=16 p17=17 p18=18 p19=19 p20=20 p21=21 p22=22 p23=23 p24=24
.param p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 p7=7 p8=8 p9=9 p10=10 p11=11 p12=12
+ p13=13 p14=14 p15=15 p16=16 p17=17 p18=18 p19=19 p20=20 p21=21 p22=22 p23=23 p24=24
.param p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 p7=7 p8=8 p9=9 p10=10 p11=11 p12=12
+ p13=13 p14=14 p15=15 p16=16 p17=17 p18=18 p19=19 p20=20 p21=21 p22=22 p23=23 p24=24
.param p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 p7=7 p8=8 p9=9 p10=10 p11=11 p12=12
+ p13=13 p14=14 p15=15 p16=16 p17=17 p18=18 p19=19 p20=20 p21=21 p22=22 p23=23 p24=24
.param p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 p7=7 p8=8 p9=9 p10=10 p11=11 p12=12
+ p13=13 p14=14 p15=15 p16=16 p17=17 p18=18 p19=19 p20=20 p21=21 p22=22 p23=23 p24=24
.param p1=1 p2=2 p3=3 p4=4 p5=5 p6=6 p7=7 p8=8 p9=9 p10=10 p11=11 p12=12
+ p13=13 p14=14 p15=15 p16=16 p17=17 p18=18 p19=19 p20=20 p21=21 p22=22 p23=23 p24=24

m1 d g s b mos l=1 w=2 a1=1 a2 = 2
.inc 'somefile'
.ends mysubckt1

...

$grammar = <<'...';
# This is the Pegex Grammar
%grammar HSPICE
# %version 0.01

file: document* atom*

atom: lib
    | model
    | subckt
    | paramgroup
    | include
    | option
    | instance
    | .blank
    | .comment

document: comment =blank
blank: / (= ALL) - (: EOL | EOS )/
comment: / ( (: star_line )+ ) /
star_line: / (= ALL) (: BLANK* STAR [^ EOL]* ) (: EOL| EOS) /

lib: comment*
    lib_begin .sep lib_name .sep? EOL
    atom*
    lib_end .sep lib_name .sep? ( EOL | EOS )
lib_begin: '.lib' | '.LIB'
lib_end: '.endl' | '.ENDL'

subckt: comment*
    subckt_begin .sep subckt_name .sep nodes .sep param_list .sep? EOL
    atom*
    subckt_end .sep subckt_name .sep? ( EOL | EOS )
subckt_begin: '.subckt' | '.SUBCKT'
subckt_end: '.ends' | '.ENDS'
nodes: / ( node (: BLANK+ node )* ) (= sep WORD+ BLANK* EQUAL ) /
node: / (: WORD+ ) /

model: comment*
    model_begin .sep model_name .sep model_type .sep param_list
model_begin: '.model' | '.MODEL'

paramgroup: comment*
    paramgroup_begin .sep param_list ( EOL | EOS )
paramgroup_begin: '.param' | '.PARAM' | '.para' | '.PARA'

param_list: param* % .sep .BLANK*
param: name .BLANK* EQUAL .BLANK* value

include: comment*
    ( inc_inc | inc_lib )
inc_inc: inc_inc_begin .sep
    filename
inc_inc_begin: '.inc' | '.INC'

inc_lib: inc_lib_begin .sep
    filename .sep
    lib_name
inc_lib_begin: '.lib' | '.LIB'

option: comment*
    option_begin
    ( .sep param_list )?
option_begin: '.option' | '.OPTION'


instance: comment*
    (
       mos
    )
    ( EOL | EOS )

mos: /([mM] WORD+ ) + d + g + s + b + model_name /
    ( .sep
      param_list
    )?

d: / ( WORD+ ) /
g: / ( WORD+ ) /
s: / ( WORD+ ) /
b: / ( WORD+ ) /




name: / ( WORD+ ) /
value: /(
    quote
  | operand
) /

quote: /(: SINGLE (: [^ SINGLE]* ) SINGLE )/
operand: /(: func | var | number )/

var: /(: [a-zA-Z_] WORD* )/
func: /( var LPAREN ANY* RPAREN )/
number: /(:
    [ DASH PLUS ]?
    (: 0 | [1-9] DIGIT* )
    (: DOT DIGIT* )?
    (: [eE] [ DASH PLUS ]? DIGIT+ )?
    (: [munapv] )?
)
/

lib_name: /( WORD+ )/
subckt_name: /( WORD+ )/
model_name: /( WORD+ )/
instance_name: /( WORD+ )/
model_type: /( WORD+ )/
filename: / ( SINGLE (: [^ SINGLE] )* SINGLE )/

sep: /(:
      BLANK* EOL (: comment | blank )* BLANK* PLUS BLANK*
    | BLANK+
)/
...
