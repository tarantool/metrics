.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec
	tarantoolctl rocks make
	tarantoolctl rocks install luatest 0.5.0

.PHONY: test
test: .rocks
	.rocks/bin/luatest

.PHONY: clean
clean:
	rm -rf .rocks
