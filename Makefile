TTCTL := tt
ifeq (,$(shell which tt 2>/dev/null))
$(error tt is not found)
endif

.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec metrics/*.lua metrics/*/*.lua
	$(TTCTL) rocks make
	$(TTCTL) rocks install luatest # master newer than 0.5.7 required
	$(TTCTL) rocks install luacov 0.13.0
	$(TTCTL) rocks install luacheck 0.26.0
	if [ -n '$(CARTRIDGE_VERSION)' ]; then \
		$(TTCTL) rocks install cartridge $(CARTRIDGE_VERSION); \
	fi

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest -v -c

.PHONY: test_with_coverage_report
test_with_coverage_report: .rocks
	rm -f tmp/luacov.*.out*
	.rocks/bin/luatest --coverage -v -c --shuffle group --repeat 3
	.rocks/bin/luacov .
	echo
	grep -A999 '^Summary' tmp/luacov.report.out

.PHONY: test_promtool
test_promtool: .rocks
	tarantool test/promtool.lua
	cat prometheus-input | promtool check metrics
	rm prometheus-input

update-pot:
	sphinx-build doc/monitoring doc/locale/en/ -c doc/ -d doc/.doctrees -b gettext

update-po:
	sphinx-intl update -p doc/locale/en/ -d doc/locale/ -l "ru"

.PHONY: clean
clean:
	rm -rf .rocks
