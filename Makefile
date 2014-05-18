.PHONY: cpan test

NAME := $(shell grep '^name: ' Meta | cut -d' ' -f2)
VERSION := $(shell grep '^version: ' Meta | cut -d' ' -f2)

test:
	prove -lv test

cpan:
	./.cpan/bin/make-cpan

test-cpan: cpan
	(cd cpan; dzil test)

dist: cpan
	(cd cpan; dzil build)

release: dist
	cpan-upload cpan/$(NAME)-$(VERSION).tar.gz
	git tag $(VERSION)
	git push --tag

clean purge:
	rm -fr cpan

