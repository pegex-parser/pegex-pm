.PHONY: cpan test

NAME := $(shell grep '^name: ' Meta | cut -d' ' -f2)
VERSION := $(shell grep '^version: ' Meta | cut -d' ' -f2)
DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz

test:
	prove -lv test

cpan:
	./.cpan/bin/make-cpan

test-cpan: cpan
	(cd cpan; dzil test) && rm -fr cpan

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
