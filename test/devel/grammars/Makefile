GRAMMARS := \
    json.pgx \
    kwim.pgx \
    pegex.pgx \
    swim.pgx \
    testml.pgx \
    vic.pgx \
    yaml.pgx \

REPOS := $(GRAMMARS:%.pgx=%-pgx)


#------------------------------------------------------------------------------
update: $(GRAMMARS)

clean:
	rm -fr $(REPOS) testml

#------------------------------------------------------------------------------
%.pgx: %-pgx
	cp $</$@ $@

testml.pgx: testml
	cp $</src/testml-pgx/$@ $@

#------------------------------------------------------------------------------
json-pgx pegex-pgx:
	git clone https://github.com/pegex-parser/$@

kwim-pgx swim-pgx yaml-pgx:
	git clone https://github.com/ingydotnet/$@

testml:
	git clone https://github.com/testml-lang/$@

vic-pgx:
	git clone https://github.com/selectiveintellect/$@
