local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

local Summary = require('metrics.collectors.summary')

g.test_collect = function()
    local instance = Summary:new('latency')
    instance:observe(1)
    instance:observe(2)
    instance:observe(3, {tag = 'a'})
    instance:observe(4, {tag = 'a'})
    instance:observe(5, {tag = 'b'})

    utils.assert_observations(instance:collect(), {
        {'latency_count', 2, {}},
        {'latency_sum', 3, {}},
        {'latency_count', 2, {tag = 'a'}},
        {'latency_sum', 7, {tag = 'a'}},
        {'latency_count', 1, {tag = 'b'}},
        {'latency_sum', 5, {tag = 'b'}},
    })
end
