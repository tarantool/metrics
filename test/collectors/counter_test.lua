local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local utils = require('test.utils')

g.before_all(utils.init)

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
