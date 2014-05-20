.PHONY: cpan doc test

NAME := $(shell grep '^name: ' Meta 2>/dev/null | cut -d' ' -f2)
VERSION := $(shell grep '^version: ' Meta 2>/dev/null | cut -d' ' -f2)
DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz

default: help

help:
	@echo ''
	@echo 'Makefile targets:'
	@echo ''
	@echo '    make test     - Run the repo tests'
	@echo '    make install  - Install the repo'
	@echo '    make doc      - Make the docs'
	@echo ''
	@echo '    make cpan     - Make cpan/ dir with dist.ini'
	@echo '    make dist     - Make CPAN distribution tarball'
	@echo '    make distdir  - Make CPAN distribution directory'
	@echo '    make disttest - Run the dist tests'
	@echo '    make publish  - Publish the dist to CPAN'
	@echo '    make publish-dryrun   - Don'"'"'t actually push to CPAN'
	@echo ''
	@echo '    make upgrade  - Upgrade the build system'
	@echo '    make clean    - Clean up build files'
	@echo ''

test:
	prove -lv test

install: distdir
	(cd $(DISTDIR); perl Makefile.PL; make install)
	make clean

doc:
	kwim --pod-cpan doc/$(NAME).kwim > ReadMe.pod

cpan:
	./.pkg/bin/make-cpan

dist: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	rm -fr cpan

distdir: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	tar xzf $(DIST)
	rm -fr cpan $(DIST)

disttest: cpan
	(cd cpan; dzil test) && rm -fr cpan

publish: check-release dist
	cpan-upload $(DIST)
	git tag $(VERSION)
	git push --tag
	rm $(DIST)

publish-dryrun: check-release dist
	echo cpan-upload $(DIST)
	echo git tag $(VERSION)
	echo git push --tag
	rm $(DIST)

clean purge:
	rm -fr cpan .build $(DIST) $(DISTDIR)

upgrade:
	(PKGREPO=$(PWD) make -C ../perl5-pkg do-upgrade)

#------------------------------------------------------------------------------
check-release:
	./.pkg/bin/check-release

do-upgrade:
	mkdir -p $(PKGREPO)/.pkg/bin
	cp Makefile $(PKGREPO)/Makefile
	cp dist.ini $(PKGREPO)/.pkg/
	cp -r bin/* $(PKGREPO)/.pkg/bin/
