local t = require('luatest')
local g = t.group()

local fun = require('fun')
local Shared = require('metrics.collectors.shared')

g.test_different_order_in_label_pairs = function()
    local class = Shared:new_class('test_class', {'inc'})
    local collector = class:new('test')
    collector:inc(1, {a = 1, b = 2})
    collector:inc(1, {a = 2, b = 1})
    collector:inc(1, {b = 2, a = 1})
    local observations = collector:collect()
    t.assert_items_equals(fun.iter(observations):map(function(x) return {x.value, x.label_pairs} end):totable(), {
        {2, {a = 1, b = 2}},
        {1, {a = 2, b = 1}},
    })
end
