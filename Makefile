.PHONY: cpan test

NAME := $(shell grep '^name: ' Meta 2>/dev/null | cut -d' ' -f2)
VERSION := $(shell grep '^version: ' Meta 2>/dev/null | cut -d' ' -f2)
DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz

test:
	prove -lv test

cpan:
	./.cpan/bin/make-cpan

test-cpan: cpan
	(cd cpan; dzil test) && rm -fr cpan

install: distdir
	(cd $(DISTDIR); perl Makefile.PL; make install)
	make clean

dist: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	rm -fr cpan

distdir: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	tar xzf $(DIST)
	rm -fr cpan $(DIST)

release: check-release dist
	cpan-upload $(DIST)
	git tag $(VERSION)
	git push --tag
	rm $(DIST)

check-release:
	./.cpan/bin/check-release

clean purge:
	rm -fr cpan $(DIST) $(DISTDIR)

upgrade:
	(PERL5REPO=$(PWD) make -C ../perl5-pkg do-upgrade)

do-upgrade:
	mkdir -p $(PERL5REPO)/.cpan/bin
	cp Makefile $(PERL5REPO)/Makefile
	cp dist.ini $(PERL5REPO)/.cpan/
	cp -r bin/* $(PERL5REPO)/.cpan/bin/
