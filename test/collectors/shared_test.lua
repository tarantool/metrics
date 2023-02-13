local t = require('luatest')
local g = t.group()

local luatest_capture = require('luatest.capture')

local utils = require('test.utils')
local Shared = require('metrics.collectors.shared')

g.test_different_order_in_label_pairs = function()
    local class = Shared:new_class('test_class', {'inc'})
    local collector = class:new('test')
    collector:inc(1, {a = 1, b = 2})
    collector:inc(1, {a = 2, b = 1})
    collector:inc(1, {b = 2, a = 1})
    utils.assert_observations(collector:collect(), {
        {'test', 2, {a = 1, b = 2}},
        {'test', 1, {a = 2, b = 1}},
    })
end

g.test_remove_metric_by_label = function()
    local class = Shared:new_class('test_class', {'inc'})
    local collector = class:new('test')
    collector:inc(1, {a = 1, b = 2})
    collector:inc(1, {a = 2, b = 1})
    utils.assert_observations(collector:collect(), {
        {'test', 1, {a = 1, b = 2}},
        {'test', 1, {a = 2, b = 1}},
    })
    collector:remove({a = 2, b = 1})
    utils.assert_observations(collector:collect(), {
        {'test', 1, {a = 1, b = 2}},
    })
end

g.test_metainfo = function()
    local metainfo = {my_useful_info = 'here'}
    local c = Shared:new('collector', nil, metainfo)
    t.assert_equals(c.metainfo, metainfo)
end


g.test_metainfo_immutable = function()
    local metainfo = {my_useful_info = 'here'}
    local c = Shared:new('collector', nil, metainfo)
    metainfo['my_useful_info'] = 'there'
    t.assert_equals(c.metainfo, {my_useful_info = 'here'})
end

local control_characters_cases = {
    in_kind = function()
        Shared:new_class('test_class\tlab', {'inc'})
    end,
    in_name = function()
        local class = Shared:new_class('test_class', {'inc'})
        class:new('test\tlab')
    end,
    in_observation_label_key = function()
        local class = Shared:new_class('test_class', {'inc'})
        local collector = class:new('test')
        collector:inc(1, {['lab\tval\tlab2'] = 'val2'})
    end,
    in_observation_label_value = function()
        local class = Shared:new_class('test_class', {'inc'})
        local collector = class:new('test')
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

local name_prefix_cases = {
    without_suffix = {
        name = 'my_metric',
        name_prefix = 'my_metric',
    },
    with_current_suffix = {
        name = 'my_metric_current',
        name_prefix = 'my_metric',
    },
    with_total_suffix = {
        name = 'my_metric_total',
        name_prefix = 'my_metric',
    },
    with_current_not_as_suffix = {
        name = 'electrical_current_value',
        name_prefix = 'electrical_current_value',
    },
    with_total_not_as_suffix = {
        name = 'sold_total_overdose_dvds',
        name_prefix = 'sold_total_overdose_dvds',
    },
}

for name, case in pairs(name_prefix_cases) do
    g['test_name_prefix_if_' .. name] = function()
        local class = Shared:new_class(case.name .. '_class', {'inc'})
        local c = class:new(case.name)
        t.assert_equals(c.name_prefix, case.name_prefix)
    end
end

g.test_collect_extended = function()
    local class = Shared:new_class('test_class', {'inc'})
    local c = class:new('test', nil, {my_useful_info = 'here'})
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
