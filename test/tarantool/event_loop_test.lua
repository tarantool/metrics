require('strict').on()

local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local fiber = require('fiber')
local utils = require('test.utils')

local event_loop = require('metrics.tarantool.event_loop')

g.before_each(function ()
    metrics.enable_default_metrics()
    metrics.invoke_callbacks()
    fiber.yield() -- yield to call monitor fiber
end)

g.after_each(metrics.clear)

g.test_event_loop_metrics_present = function()
    local event_loop_metrics = utils.find_metric('tnt_tx_loop_delay', metrics.collect())
    t.assert_equals(#event_loop_metrics, 2)
end

g.test_remove_metric = function()
    local event_loop_metrics = utils.find_metric('tnt_tx_loop_delay', metrics.collect())

    t.assert_equals(#event_loop_metrics, 2)

    local collector = event_loop.list.tnt_tx_loop_delay
    metrics.registry:unregister(collector)
    table.clear(event_loop.list)

    event_loop_metrics = utils.find_metric('tnt_tx_loop_delay', metrics.collect()) or {}
    t.assert_equals(#event_loop_metrics, 0)
end

g.test_add_metric_after_remove = function()
    local event_loop_metrics = utils.find_metric('tnt_tx_loop_delay', metrics.collect())
    t.assert_equals(#event_loop_metrics, 2)

    local collector = event_loop.list.tnt_tx_loop_delay
    metrics.registry:unregister(collector)
    table.clear(event_loop.list)

    event_loop_metrics = utils.find_metric('tnt_tx_loop_delay', metrics.collect()) or {}
    t.assert_equals(#event_loop_metrics, 0)

    metrics.invoke_callbacks()
    fiber.yield()

    event_loop_metrics = utils.find_metric('tnt_tx_loop_delay', metrics.collect())
    t.assert_equals(#event_loop_metrics, 2)

end
