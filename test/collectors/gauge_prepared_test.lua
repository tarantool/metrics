local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local utils = require('test.utils')

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_gauge_prepared = function()
    local gauge = metrics.gauge('gauge', 'some gauge')
    local prepared = gauge:prepare({})

    prepared:inc(3)
    prepared:dec(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('gauge', {}, observations)
    t.assert_equals(utils.len(collectors), 1, 'gauge seen as only collector')
    t.assert_equals(obs.value, -2, '3 - 5 = -2 (via metrics.collectors())')

    t.assert_equals(gauge:collect()[1].value, -2, '3 - 5 = -2')

    prepared:set(-8)

    t.assert_equals(gauge:collect()[1].value, -8, 'after set(-8) = -8')

    prepared:inc(-1)
    prepared:dec(-2)

    t.assert_equals(gauge:collect()[1].value, -7, '-8 + (-1) - (-2)')
end

g.test_gauge_prepared_remove_metric_by_label = function()
    local c = metrics.gauge('gauge')

    local prepared1 = c:prepare({label = 1})
    local prepared2 = c:prepare({label = 2})

    prepared1:set(1)
    prepared2:set(1)

    utils.assert_observations(c:collect(), {
        {'gauge', 1, {label = 1}},
        {'gauge', 1, {label = 2}},
    })

    prepared1:remove()
    utils.assert_observations(c:collect(), {
        {'gauge', 1, {label = 2}},
    })
end

g.test_gauge_prepared_inc_non_number = function()
    local c = metrics.gauge('gauge')
    local prepared = c:prepare({})

    t.assert_error_msg_contains('Collector increment should be a number', prepared.inc, prepared, true)
end

g.test_gauge_prepared_dec_non_number = function()
    local c = metrics.gauge('gauge')
    local prepared = c:prepare({})

    t.assert_error_msg_contains('Collector decrement should be a number', prepared.dec, prepared, true)
end

g.test_gauge_prepared_set_non_number = function()
    local c = metrics.gauge('gauge')
    local prepared = c:prepare({})

    t.assert_error_msg_contains('Collector set value should be a number', prepared.set, prepared, true)
end

g.test_gauge_prepared_with_fixed_labels = function()
    local fixed_labels = {'label1', 'label2'}
    local gauge = metrics.gauge('gauge_with_labels', nil, {}, fixed_labels)

    local prepared1 = gauge:prepare({label1 = 1, label2 = 'text'})
    prepared1:set(1)
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', 1, {label1 = 1, label2 = 'text'}},
    })

    local prepared2 = gauge:prepare({label2 = 'text', label1 = 100})
    prepared2:set(42)
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', 1, {label1 = 1, label2 = 'text'}},
        {'gauge_with_labels', 42, {label1 = 100, label2 = 'text'}},
    })

    prepared2:inc(5)
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', 1, {label1 = 1, label2 = 'text'}},
        {'gauge_with_labels', 47, {label1 = 100, label2 = 'text'}},
    })

    prepared1:dec(11)
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', -10, {label1 = 1, label2 = 'text'}},
        {'gauge_with_labels', 47, {label1 = 100, label2 = 'text'}},
    })

    prepared2:remove()
    utils.assert_observations(gauge:collect(), {
        {'gauge_with_labels', -10, {label1 = 1, label2 = 'text'}},
    })
end

g.test_gauge_prepared_missing_label = function()
    local fixed_labels = {'label1', 'label2'}
    local gauge = metrics.gauge('gauge_with_labels', nil, {}, fixed_labels)

    -- Test that prepare validates labels
    t.assert_error_msg_contains(
        "should match the number of label pairs",
        gauge.prepare, gauge, {label1 = 1, label2 = 'text', label3 = 42})

    local function assert_missing_label_error(fun, ...)
        t.assert_error_msg_contains(
            "is missing",
            fun, gauge, ...)
    end

    assert_missing_label_error(gauge.prepare, {label1 = 1, label3 = 42})
end

g.test_gauge_prepared_multiple_labels = function()
    local g = metrics.gauge('temp')

    -- Test multiple prepared statements with different labels
    local prepared1 = g:prepare({location = 'server1', sensor = 'cpu'})
    local prepared2 = g:prepare({location = 'server2', sensor = 'cpu'})
    local prepared3 = g:prepare({location = 'server1', sensor = 'memory'})

    prepared1:set(65.5)
    prepared2:set(72.3)
    prepared3:set(45.2)

    utils.assert_observations(g:collect(), {
        {'temp', 65.5, {location = 'server1', sensor = 'cpu'}},
        {'temp', 72.3, {location = 'server2', sensor = 'cpu'}},
        {'temp', 45.2, {location = 'server1', sensor = 'memory'}},
    })

    -- Test increment/decrement on existing prepared statements
    prepared1:inc(2.5)
    prepared2:dec(1.3)

    utils.assert_observations(g:collect(), {
        {'temp', 68.0, {location = 'server1', sensor = 'cpu'}},
        {'temp', 71.0, {location = 'server2', sensor = 'cpu'}},
        {'temp', 45.2, {location = 'server1', sensor = 'memory'}},
    })
end

g.test_gauge_prepared_methods = function()
    local g = metrics.gauge('gauge')
    local prepared = g:prepare({label = 'test'})

    -- Test that prepared has the right methods
    t.assert_not_equals(prepared.inc, nil, "prepared should have inc method")
    t.assert_not_equals(prepared.dec, nil, "prepared should have dec method")
    t.assert_not_equals(prepared.set, nil, "prepared should have set method")
    t.assert_not_equals(prepared.remove, nil, "prepared should have remove method")

    -- Test that prepared doesn't have counter-specific methods
    t.assert_equals(prepared.reset, nil, "gauge prepared shouldn't have reset method")
    t.assert_equals(prepared.collect, nil, "prepared shouldn't have collect method")
end
