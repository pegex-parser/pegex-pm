BASE=../lib/Pegex/Grammar

$(BASE)/Pegex.pm: pegex.pgx grammar.pl Makefile
	perl grammar.pl $< > $@
