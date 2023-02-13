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

local control_characters_cases = {
    in_name = function()
        metrics.gauge('gauge\tlab')
    end,
    in_observation_label_key = function()
        local collector = metrics.gauge('gauge')
        collector:set(1, {['lab\tval\tlab2'] = 'val2'})
    end,
    in_observation_label_value = function()
        local collector = metrics.gauge('gauge')
        collector:set(1, {lab = 'val\tlab2\tval2'})
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
    local c = metrics.gauge('gauge', nil, {my_useful_info = 'here'})
    c:set(3, {mylabel = 'myvalue1'})
    c:set(2, {mylabel = 'myvalue2'})

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
