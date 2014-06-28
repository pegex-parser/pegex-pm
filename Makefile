# DO NOT EDIT.
#
# This Makefile came from Zilla::Dist. To upgrade it, run:
#
#   > make upgrade
#

.PHONY: cpan test

ifeq (,$(shell which zild))
    $(error "Error: 'zild' command not found. Please install Zilla::Dist from CPAN")
endif

NAME := $(shell zild meta name)
VERSION := $(shell zild meta version)
DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz
NAMEPATH := $(subst -,/,$(NAME))
SUCCESS := "$(DIST) Released!!!"

default: help

help:
	@echo ''
	@echo 'Makefile targets:'
	@echo ''
	@echo '    make test      - Run the repo tests'
	@echo '    make install   - Install the repo'
	@echo '    make update    - Update generated files'
	@echo ''
	@echo '    make cpan      - Make cpan/ dir with dist.ini'
	@echo '    make cpanshell - Open new shell into new cpan/'
	@echo '    make cpantest  - Make cpan/ dir and run tests in it'
	@echo ''
	@echo '    make dist      - Make CPAN distribution tarball'
	@echo '    make distdir   - Make CPAN distribution directory'
	@echo '    make distshell - Open new shell into new distdir'
	@echo '    make disttest  - Run the dist tests'
	@echo ''
	@echo '    make release   - Release the dist to CPAN'
	@echo '    make preflight - Dryrun of release'
	@echo ''
	@echo '    make readme    - Make the ReadMe.pod file'
	@echo '    make travis    - Make a travis.yml file'
	@echo '    make upgrade   - Upgrade the build system'
	@echo ''
	@echo '    make clean     - Clean up build files'
	@echo ''

test:
	prove -lv test

install: distdir
	(cd $(DISTDIR); perl Makefile.PL; make install)
	make clean

update: makefile
	make readme travis version

cpan:
	zild-make-cpan

cpanshell: cpan
	(cd cpan; $$SHELL)
	make clean

cpantest: cpan
	(cd cpan; prove -lv t) && make clean

dist: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	rm -fr cpan

distdir: clean cpan
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	tar xzf $(DIST)
	rm -fr cpan $(DIST)

distshell: distdir
	(cd $(DISTDIR); $$SHELL)
	make clean

disttest: cpan
	(cd cpan; dzil test) && make clean

release: clean update check-release test disttest
	make dist
	cpan-upload $(DIST)
	git push
	git tag $(VERSION)
	git push --tag
	make clean
	git status
	@echo
	@[ -n "$$(which cowsay)" ] && cowsay "$(SUCCESS)" || echo "$(SUCCESS)"
	@echo

preflight: clean update check-release test disttest
	make dist
	@echo cpan-upload $(DIST)
	@echo git push
	@echo git tag $(VERSION)
	@echo git push --tag
	make clean
	git status
	@echo
	@[ -n "$$(which cowsay)" ] && cowsay "$(SUCCESS)" || echo "$(SUCCESS)"
	@echo

readme:
	swim --pod-cpan doc/$(NAMEPATH).swim > ReadMe.pod

travis:
	zild-make-travis

upgrade:
	cp `zild sharedir`/Makefile ./

clean purge:
	rm -fr cpan .build $(DIST) $(DISTDIR)

#------------------------------------------------------------------------------
check-release:
	zild-check-release

ifeq (Zilla-Dist,$(NAME))
makefile:
	@echo Skip 'make upgrade'
else
makefile: upgrade
endif

version:
	zild-version-update
