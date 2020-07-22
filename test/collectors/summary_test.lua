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
        {'latency_avg', 1.5, {}},
        {'latency_count', 2, {tag = 'a'}},
        {'latency_avg', 3.5, {tag = 'a'}},
        {'latency_count', 1, {tag = 'b'}},
        {'latency_avg', 5, {tag = 'b'}},
    })

    utils.assert_observations(instance:collect(), {
        {'latency_count', 2, {}},
        {'latency_avg', 0, {}},
        {'latency_count', 2, {tag = 'a'}},
        {'latency_avg', 0, {tag = 'a'}},
        {'latency_count', 1, {tag = 'b'}},
        {'latency_avg', 0, {tag = 'b'}},
    })
end
