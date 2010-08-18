BASE=../lib/Pegex/Compiler

$(BASE)/Grammar.pm: pegex.pgx grammar.pl Makefile
	perl grammar.pl $< > $@
