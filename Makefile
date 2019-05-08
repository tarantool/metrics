.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.PHONY: test
test:
	./tests/collectors.lua
