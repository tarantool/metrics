local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local utils = require('test.utils')

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

g.test_metainfo = function()
    local metainfo = {my_useful_info = 'here'}
    local c = metrics.gauge('gauge', nil, metainfo)
    t.assert_equals(c.metainfo, metainfo)
end

g.test_metainfo_immutable = function()
    local metainfo = {my_useful_info = 'here'}
    local c = metrics.gauge('gauge', nil, metainfo)
    metainfo['my_useful_info'] = 'there'
    t.assert_equals(c.metainfo, {my_useful_info = 'here'})
end

g.test_gauge_with_fixed_labels = function()
    local fixed_labels = {'label1', 'label2'}
    local gauge = metrics.gauge('gauge_with_labels', nil, {}, fixed_labels)

    gauge:set(1, {label1 = 1, label2 = 'text'})
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', 1, {label1 = 1, label2 = 'text'}},
    })

    gauge:set(42, {label2 = 'text', label1 = 100})
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', 1, {label1 = 1, label2 = 'text'}},
        {'gauge_with_labels', 42, {label1 = 100, label2 = 'text'}},
    })

    gauge:inc(5, {label2 = 'text', label1 = 100})
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', 1, {label1 = 1, label2 = 'text'}},
        {'gauge_with_labels', 47, {label1 = 100, label2 = 'text'}},
    })

    gauge:dec(11, {label1 = 1, label2 = 'text'})
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', -10, {label1 = 1, label2 = 'text'}},
        {'gauge_with_labels', 47, {label1 = 100, label2 = 'text'}},
    })

    gauge:remove({label2 = 'text', label1 = 100})
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', -10, {label1 = 1, label2 = 'text'}},
    })
end

g.test_gauge_missing_label = function()
    local fixed_labels = {'label1', 'label2'}
    local gauge = metrics.gauge('gauge_with_labels', nil, {}, fixed_labels)

    gauge:set(42, {label1 = 1, label2 = 'text'})
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', 42, {label1 = 1, label2 = 'text'}},
    })

    t.assert_error_msg_contains(
        "Invalid label_pairs: expected a table when label_keys is provided",
        gauge.set, gauge, 42, 'text')

    t.assert_error_msg_contains(
        "should match the number of label pairs",
        gauge.set, gauge, 42, {label1 = 1, label2 = 'text', label3 = 42})

    local function assert_missing_label_error(fun, ...)
        t.assert_error_msg_contains(
            "is missing",
            fun, gauge, ...)
    end

    assert_missing_label_error(gauge.inc, 1, {label1 = 1, label3 = 42})
    assert_missing_label_error(gauge.dec, 2, {label1 = 1, label3 = 42})
    assert_missing_label_error(gauge.set, 42, {label2 = 'text', label3 = 42})
    assert_missing_label_error(gauge.remove, {label2 = 'text', label3 = 42})
end
