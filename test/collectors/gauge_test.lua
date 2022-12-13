local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local utils = require('test.utils')

g.before_all(utils.init)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_gauge = function()
    t.assert_error_msg_contains("bad argument #1 to gauge (string expected, got nil)", function()
        metrics.gauge()
    end)

    t.assert_error_msg_contains("bad argument #1 to gauge (string expected, got number)", function()
        metrics.gauge(2)
    end)

    local gauge = metrics.gauge('gauge', 'some gauge')

    gauge:inc(3)
    gauge:dec(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('gauge', {}, observations)
    t.assert_equals(utils.len(collectors), 1, 'gauge seen as only collector')
    t.assert_equals(obs.value, -2, '3 - 5 = -2 (via metrics.collectors())')

    t.assert_equals(gauge:collect()[1].value, -2, '3 - 5 = -2')

    gauge:set(-8)

    t.assert_equals(gauge:collect()[1].value, -8, 'after set(-8) = -8')

    gauge:inc(-1)
    gauge:dec(-2)

    t.assert_equals(gauge:collect()[1].value, -7, '-8 + (-1) - (-2)')
end

g.test_gauge_remove_metric_by_label = function()
    local c = metrics.gauge('gauge')

    c:set(1, {label = 1})
    c:set(1, {label = 2})

    utils.assert_observations(c:collect(), {
        {'gauge', 1, {label = 1}},
        {'gauge', 1, {label = 2}},
    })

    c:remove({label = 1})
    utils.assert_observations(c:collect(), {
        {'gauge', 1, {label = 2}},
    })
end

g.test_inc_non_number = function()
    local c = metrics.gauge('gauge')

    t.assert_error_msg_contains('Collector increment should be a number', c.inc, c, true)
end

g.test_dec_non_number = function()
    local c = metrics.gauge('gauge')

    t.assert_error_msg_contains('Collector decrement should be a number', c.dec, c, true)
end

g.test_inc_non_number = function()
    local c = metrics.gauge('gauge')

    t.assert_error_msg_contains('Collector set value should be a number', c.set, c, true)
end

