.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec
	tarantoolctl rocks make
	tarantoolctl rocks install luatest 0.5.4
	tarantoolctl rocks install luacov 0.13.0
	tarantoolctl rocks install luacheck 0.26.0
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
	rm -f tmp/luacov.*.out*
	.rocks/bin/luatest --coverage -v --shuffle group --repeat 3
	.rocks/bin/luacov .
	echo
	grep -A999 '^Summary' tmp/luacov.report.out

.PHONY: test_promtool
test_promtool: .rocks
	tarantool test/promtool_test.lua
	cat prometheus-input | promtool check metrics

update-pot:
	sphinx-build doc/monitoring doc/locale/en/ -c doc/ -d doc/.doctrees -b gettext

update-po:
	sphinx-intl update -p doc/locale/en/ -d doc/locale/ -l "ru"

.PHONY: clean
clean:
	rm -rf .rocks
