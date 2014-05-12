cpan:
	./.cpan/bin/make_cpan

release: cpan
	(cd cpan; dzil release)

test-cpan: cpan
	(cd cpan; dzil test)

test:
	prove -lv test

clean:
	rm -fr cpan

