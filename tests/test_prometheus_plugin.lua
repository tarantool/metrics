#!/usr/bin/env tarantool

local metrics = require('metrics')
local tap = require('tap')

box.cfg{}

box.once("schema", function()
    local s = box.schema.space.create('random_space_for_prometheus')
    s:create_index('pk')
end)

-- Enable default metrics collections
metrics.enable_default_metrics();

local http_handler = require('metrics.plugins.prometheus').collect_http

local test = tap.test("prometheus")
test:plan(1)

test:test("Check ULL/LL postfixes at the end of value", function(test)
    test:plan(1)
    local resp = http_handler().body
    if resp:match("ULL") or resp:match("LL") then
        test:fail("Plugin output contains cdata postfixes")
        return
    end

    test:ok(true, "Plugin output isn't contains cdata postfixes")
end)

os.exit(test:check() and 0 or 1)
