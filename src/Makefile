BASE=../lib/Pegex/Grammar

# all: $(BASE)/Pegex.pm $(BASE)/Bootstrap.pm

all: grammar bootstrap

grammar: $(BASE)/Pegex.pm force

bootstrap: $(BASE)/Bootstrap.pm force

$(BASE)/Pegex.pm: pegex.pgx grammar.pl Makefile
	perl grammar.pl $< > $@.tmp
	mv $@.tmp $@

$(BASE)/Bootstrap.pm: bootstrap.pl Makefile
	perl $< > $@

force:
