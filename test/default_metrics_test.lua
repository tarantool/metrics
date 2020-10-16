#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group('default_metrics')

local metrics = require('metrics')

g.before_all(function()
    box.cfg{}
    metrics.clear()
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_default_metrics_clear = function()
    metrics.clear()
    metrics.enable_default_metrics()
    t.assert_equals(#metrics.collect(), 0)

    metrics.invoke_callbacks()
    t.assert(#metrics.collect() > 0)

    metrics.clear()
    t.assert_equals(#metrics.collect(), 0)

    metrics.enable_default_metrics()
    metrics.invoke_callbacks()
    t.assert(#metrics.collect() > 0)
end
