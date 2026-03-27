local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local utils = require('test.utils')

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_counter_prepared = function()
    local c = metrics.counter('cnt', 'some counter')

    -- Create prepared statement
    local prepared = c:prepare({})

    prepared:inc(3)
    prepared:inc(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('cnt', {}, observations)
    t.assert_equals(utils.len(collectors), 1, 'counter seen as only collector')
    t.assert_equals(obs.value, 8, '3 + 5 = 8 (via metrics.collectors())')

    t.assert_equals(c:collect()[1].value, 8, '3 + 5 = 8')

    t.assert_error_msg_contains("Counter increment should not be negative", function()
        prepared:inc(-1)
    end)

    t.assert_equals(prepared.dec, nil, "Counter prepared doesn't have 'decrease' method")

    prepared:inc(0)
    t.assert_equals(c:collect()[1].value, 8, '8 + 0 = 8')
end

g.test_counter_prepared_cache = function()
    local counter_1 = metrics.counter('cnt', 'test counter')
    local counter_2 = metrics.counter('cnt', 'test counter')
    local counter_3 = metrics.counter('cnt2', 'another test counter')

    local prepared_1 = counter_1:prepare({})
    local prepared_2 = counter_2:prepare({})
    local prepared_3 = counter_3:prepare({})

    prepared_1:inc(3)
    prepared_2:inc(5)
    prepared_3:inc(7)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('cnt', {}, observations)
    t.assert_equals(utils.len(collectors), 2, 'counter_1 and counter_2 refer to the same object')
    t.assert_equals(obs.value, 8, '3 + 5 = 8')
    obs = utils.find_obs('cnt2', {}, observations)
    t.assert_equals(obs.value, 7, 'counter_3 is the only reference to cnt2')
end

g.test_counter_prepared_reset = function()
    local c = metrics.counter('cnt', 'some counter')
    local prepared = c:prepare({})

    prepared:inc()
    t.assert_equals(c:collect()[1].value, 1)
    prepared:reset()
    t.assert_equals(c:collect()[1].value, 0)
end

g.test_counter_prepared_remove_metric_by_label = function()
    local c = metrics.counter('cnt')

    local prepared1 = c:prepare({label = 1})
    local prepared2 = c:prepare({label = 2})

    prepared1:inc(1)
    prepared2:inc(1)

    utils.assert_observations(c:collect(), {
        {'cnt', 1, {label = 1}},
        {'cnt', 1, {label = 2}},
    })

    prepared1:remove()
    utils.assert_observations(c:collect(), {
        {'cnt', 1, {label = 2}},
    })
end

g.test_counter_prepared_insert_non_number = function()
    local c = metrics.counter('cnt')
    local prepared = c:prepare({})
    t.assert_error_msg_contains('Counter increment should be a number', prepared.inc, prepared, true)
end

g.test_counter_prepared_with_fixed_labels = function()
    local fixed_labels = {'label1', 'label2'}
    local counter = metrics.counter('counter_with_labels', nil, {}, fixed_labels)

    local prepared1 = counter:prepare({label1 = 1, label2 = 'text'})
    prepared1:inc(1)
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 1, {label1 = 1, label2 = 'text'}},
    })

    local prepared2 = counter:prepare({label2 = 'text', label1 = 2})
    prepared2:inc(5)
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 1, {label1 = 1, label2 = 'text'}},
        {'counter_with_labels', 5, {label1 = 2, label2 = 'text'}},
    })

    prepared1:reset()
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 0, {label1 = 1, label2 = 'text'}},
        {'counter_with_labels', 5, {label1 = 2, label2 = 'text'}},
    })

    prepared2:remove()
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 0, {label1 = 1, label2 = 'text'}},
    })
end

g.test_counter_prepared_missing_label = function()
    local fixed_labels = {'label1', 'label2'}
    local counter = metrics.counter('counter_with_labels', nil, {}, fixed_labels)

    -- Test that prepare validates labels
    t.assert_error_msg_contains(
        "should match the number of label pairs",
        counter.prepare, counter, {label1 = 1, label2 = 'text', label3 = 42})

    local function assert_missing_label_error(fun, ...)
        t.assert_error_msg_contains(
            "is missing",
            fun, counter, ...)
    end

    assert_missing_label_error(counter.prepare, {label1 = 1, label3 = 'a'})
end

g.test_counter_prepared_multiple_labels = function()
    local c = metrics.counter('cnt')

    -- Test multiple prepared statements with different labels
    local prepared1 = c:prepare({method = 'GET', status = '200'})
    local prepared2 = c:prepare({method = 'POST', status = '200'})
    local prepared3 = c:prepare({method = 'GET', status = '404'})

    prepared1:inc(10)
    prepared2:inc(5)
    prepared3:inc(2)

    utils.assert_observations(c:collect(), {
        {'cnt', 10, {method = 'GET', status = '200'}},
        {'cnt', 5, {method = 'POST', status = '200'}},
        {'cnt', 2, {method = 'GET', status = '404'}},
    })

    -- Test increment on existing prepared statement
    prepared1:inc(5)
    utils.assert_observations(c:collect(), {
        {'cnt', 15, {method = 'GET', status = '200'}},
        {'cnt', 5, {method = 'POST', status = '200'}},
        {'cnt', 2, {method = 'GET', status = '404'}},
    })
end

g.test_counter_prepared_methods = function()
    local c = metrics.counter('cnt')
    local prepared = c:prepare({label = 'test'})

    -- Test that prepared has the right methods
    t.assert_not_equals(prepared.inc, nil, "prepared should have inc method")
    t.assert_not_equals(prepared.reset, nil, "prepared should have reset method")
    t.assert_not_equals(prepared.remove, nil, "prepared should have remove method")

    -- Test that prepared doesn't have gauge methods
    t.assert_equals(prepared.dec, nil, "prepared shouldn't have dec method")
    t.assert_equals(prepared.set, nil, "prepared shouldn't have set method")
    t.assert_equals(prepared.collect, nil, "prepared shouldn't have collect method")
end
