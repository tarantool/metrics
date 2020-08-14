local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

local Summary = require('metrics.collectors.summary')

g.test_collect = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    instance:observe(1)
    instance:observe(2)
    instance:observe(3, {tag = 'a'})
    instance:observe(4, {tag = 'a'})
    instance:observe(5, {tag = 'b'})

    utils.assert_observations(instance:collect(), {
        {'latency_count', 2, {}},
        {'latency_sum', 3, {}},
        {'latency', 2, {quantile = 0.5}},
        {'latency', 2, {quantile = 0.9}},
        {'latency', 2, {quantile = 0.99}},
        {'latency_count', 2, {tag = 'a'}},
        {'latency_sum', 7, {tag = 'a'}},
        {'latency', 3, {quantile = 0.5, tag = 'a'}},
        {'latency', 4, {quantile = 0.9, tag = 'a'}},
        {'latency', 4, {quantile = 0.99, tag = 'a'}},
        {'latency_count', 1, {tag = 'b'}},
        {'latency_sum', 5, {tag = 'b'}},
        {'latency', 3, {quantile = 0.5, tag = 'b'}},
        {'latency', 5, {quantile = 0.9, tag = 'b'}},
        {'latency', 5, {quantile = 0.99, tag = 'b'}},
    })
end
