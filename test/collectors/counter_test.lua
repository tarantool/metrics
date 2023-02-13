local t = require('luatest')
local g = t.group()

local luatest_capture = require('luatest.capture')

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

local control_characters_cases = {
    in_name = function()
        metrics.counter('cnt\tlab')
    end,
    in_observation_label_key = function()
        local collector = metrics.counter('cnt')
        collector:inc(1, {['lab\tval\tlab2'] = 'val2'})
    end,
    in_observation_label_value = function()
        local collector = metrics.counter('cnt')
        collector:inc(1, {lab = 'val\tlab2\tval2'})
    end,
}

for name, case in pairs(control_characters_cases) do
    g['test_control_characters_' .. name .. 'are_not_expected'] = function()
        local capture = luatest_capture:new()
        capture:enable()

        case()

        local stdout = utils.fflush_main_server_output(nil, capture)
        capture:disable()

        t.assert_str_contains(
            stdout,
            'Do not use control characters, this will raise an error in the future.')
    end
end

g.test_collect_extended = function()
    local c = metrics.counter('cnt', nil, {my_useful_info = 'here'})
    c:inc(3, {mylabel = 'myvalue1'})
    c:inc(2, {mylabel = 'myvalue2'})

    local res = c:collect{extended_format = true}
    t.assert_type(res, 'table')
    t.assert_equals(res.name, c.name)
    t.assert_equals(res.name_prefix, c.name_prefix)
    t.assert_equals(res.kind, c.kind)
    t.assert_equals(res.help, c.help)
    t.assert_equals(res.metainfo, c.metainfo)
    t.assert_gt(res.timestamp, 0)
    t.assert_type(res.observations, 'table')
    t.assert_type(res.observations[''], 'table')
    t.assert_equals(utils.len(res.observations['']), 2)
    for _, v in pairs(res.observations['']) do
        t.assert_type(v.value, 'number')
        t.assert_type(v.label_pairs, 'table')
        t.assert_type(v.label_pairs['mylabel'], 'string')
    end
end
