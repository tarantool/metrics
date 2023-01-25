local t = require('luatest')
local g = t.group()

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
