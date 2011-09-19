.PHONY: all force

BASE=../lib/Pegex/Grammar

# all: $(BASE)/Pegex.pm $(BASE)/Bootstrap.pm

all: grammar

grammar: $(BASE)/Pegex.pm force

$(BASE)/Pegex.pm: pegex.pgx grammar.pl Makefile
	perl grammar.pl $< > $@.tmp
	mv $@.tmp $@

force:
