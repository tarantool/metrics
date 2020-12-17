SHELL := /bin/bash

.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec
	tarantoolctl rocks make
	tarantoolctl rocks install luatest 0.5.0
	tarantoolctl rocks install luacov 0.13.0
	tarantoolctl rocks install luacheck 0.25.0
	if [ -z $(CARTRIDGE_VERSION) ]; then \
		tarantoolctl rocks install http 2.1.0; \
	else \
		tarantoolctl rocks install cartridge $(CARTRIDGE_VERSION); \
	fi

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest

.PHONY: test_with_coverage_report
test_with_coverage_report: .rocks
	.rocks/bin/luatest --coverage -v

.PHONY: test_promtool
test_promtool: .rocks
	tarantool test/promtool_test.lua
	cat prometheus-input | promtool check metrics

.PHONY: clean
clean:
	rm -rf .rocks
