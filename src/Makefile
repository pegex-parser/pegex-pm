.PHONY: all

all: grammar

grammar: ../lib/Pegex/Pegex/Grammar.pm force

../lib/Pegex/Pegex/Grammar.pm: pegex.pgx grammar.pl Makefile
	perl grammar.pl $< > $@.tmp
	mv $@.tmp $@

force:
