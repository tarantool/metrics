.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.PHONY: test
test:
	./run_tests.sh
