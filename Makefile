.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec
	tarantoolctl rocks make
	tarantoolctl rocks install luatest 0.5.0
	tarantoolctl rocks install luacheck 0.25.0

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest

.PHONY: clean
clean:
	rm -rf .rocks
