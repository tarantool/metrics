local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local utils = require('test.utils')

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_counter = function()
    t.assert_error_msg_contains("bad argument #1 to counter (string expected, got nil)", function()
        metrics.counter()
    end)

    t.assert_error_msg_contains("bad argument #1 to counter (string expected, got number)", function()
        metrics.counter(2)
    end)

    local c = metrics.counter('cnt', 'some counter')

    c:inc(3)
    c:inc(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('cnt', {}, observations)
    t.assert_equals(utils.len(collectors), 1, 'counter seen as only collector')
    t.assert_equals(obs.value, 8, '3 + 5 = 8 (via metrics.collectors())')

    t.assert_equals(c:collect()[1].value, 8, '3 + 5 = 8')

    t.assert_error_msg_contains("Counter increment should not be negative", function()
        c:inc(-1)
    end)

    t.assert_equals(c.dec, nil, "Counter doesn't have 'decrease' method")

    c:inc(0)
    t.assert_equals(c:collect()[1].value, 8, '8 + 0 = 8')
end

g.test_counter_cache = function()
    local counter_1 = metrics.counter('cnt', 'test counter')
    local counter_2 = metrics.counter('cnt', 'test counter')
    local counter_3 = metrics.counter('cnt2', 'another test counter')

    counter_1:inc(3)
    counter_2:inc(5)
    counter_3:inc(7)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('cnt', {}, observations)
    t.assert_equals(utils.len(collectors), 2, 'counter_1 and counter_2 refer to the same object')
    t.assert_equals(obs.value, 8, '3 + 5 = 8')
    obs = utils.find_obs('cnt2', {}, observations)
    t.assert_equals(obs.value, 7, 'counter_3 is the only reference to cnt2')
end

g.test_counter_reset = function()
    local c = metrics.counter('cnt', 'some counter')
    c:inc()
    t.assert_equals(c:collect()[1].value, 1)
    c:reset()
    t.assert_equals(c:collect()[1].value, 0)
end

g.test_counter_remove_metric_by_label = function()
    local c = metrics.counter('cnt')

    c:inc(1, {label = 1})
    c:inc(1, {label = 2})

    utils.assert_observations(c:collect(), {
        {'cnt', 1, {label = 1}},
        {'cnt', 1, {label = 2}},
    })

    c:remove({label = 1})
    utils.assert_observations(c:collect(), {
        {'cnt', 1, {label = 2}},
    })
end

g.test_insert_non_number = function()
    local c = metrics.counter('cnt')
    t.assert_error_msg_contains('Counter increment should be a number', c.inc, c, true)
end

g.test_metainfo = function()
    local metainfo = {my_useful_info = 'here'}
    local c = metrics.counter('cnt', nil, metainfo)
    t.assert_equals(c.metainfo, metainfo)
end

g.test_metainfo_immutable = function()
    local metainfo = {my_useful_info = 'here'}
    local c = metrics.counter('cnt', nil, metainfo)
    metainfo['my_useful_info'] = 'there'
    t.assert_equals(c.metainfo, {my_useful_info = 'here'})
end

g.test_counter_with_fixed_labels = function()
    local fixed_labels = {'label1', 'label2'}
    local counter = metrics.counter('counter_with_labels', nil, {}, fixed_labels)

    counter:inc(1, {label1 = 1, label2 = 'text'})
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 1, {label1 = 1, label2 = 'text'}},
    })

    counter:inc(5, {label2 = 'text', label1 = 2})
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 1, {label1 = 1, label2 = 'text'}},
        {'counter_with_labels', 5, {label1 = 2, label2 = 'text'}},
    })

    counter:reset({label1 = 1, label2 = 'text'})
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 0, {label1 = 1, label2 = 'text'}},
        {'counter_with_labels', 5, {label1 = 2, label2 = 'text'}},
    })

    counter:remove({label1 = 2, label2 = 'text'})
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 0, {label1 = 1, label2 = 'text'}},
    })
end

g.test_counter_missing_label = function()
    local fixed_labels = {'label1', 'label2'}
    local counter = metrics.counter('counter_with_labels', nil, {}, fixed_labels)

    counter:inc(42, {label1 = 1, label2 = 'text'})
    utils.assert_observations(counter:collect(), {
        {'counter_with_labels', 42, {label1 = 1, label2 = 'text'}},
    })

    t.assert_error_msg_contains(
        "Invalid label_pairs: expected a table when label_keys is provided",
        counter.inc, counter, 42, 1)

    t.assert_error_msg_contains(
        "should match the number of label pairs",
        counter.inc, counter, 42, {label1 = 1, label2 = 'text', label3 = 42})

    local function assert_missing_label_error(fun, ...)
        t.assert_error_msg_contains(
            "is missing",
            fun, counter, ...)
    end

    assert_missing_label_error(counter.inc, 1, {label1 = 1, label3 = 'a'})
    assert_missing_label_error(counter.reset, {label2 = 0, label3 = 'b'})
    assert_missing_label_error(counter.remove, {label2 = 0, label3 = 'b'})
end
