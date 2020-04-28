.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec
	tarantoolctl rocks make
	tarantoolctl rocks install luatest 0.5.0
	tarantoolctl rocks install luacov 0.13.0
	tarantoolctl rocks install luacheck 0.25.0
	tarantoolctl rocks install http 2.1.0

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest

.PHONY: test_with_coverage_report
test_with_coverage_report: .rocks
	rm -f tmp/luacov.*.out*
	.rocks/bin/luatest --coverage
	.rocks/bin/luacov .
	echo
	grep -A999 '^Summary' tmp/luacov.report.out

.PHONY: clean
clean:
	rm -rf .rocks
