BASE=../lib/Pegex/Compiler

$(BASE)/Grammar.pm: pegex.pgx grammar.pl Makefile $(BASE)
	perl grammar.pl $< > $@

$(BASE):
	mkdir -p $@

clean:
	rm -fr $(BASE)
