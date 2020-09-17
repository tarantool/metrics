local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

local Summary = require('metrics.collectors.summary')

g.test_collect = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    instance:observe(1)
    instance:observe(2)
    instance:observe(3)
    instance:observe(3, {tag = 'a'})
    instance:observe(4, {tag = 'a'})
    instance:observe(5, {tag = 'a'})
    instance:observe(6, {tag = 'a'})
    instance:observe(6, {tag = 'b'})

    utils.assert_observations(instance:collect(), {
        {'latency_count', 3, {}},
        {'latency_sum', 6, {}},
        {'latency', 2, {quantile = 0.5}},
        {'latency', 3, {quantile = 0.9}},
        {'latency', 3, {quantile = 0.99}},
        {'latency_count', 4, {tag = 'a'}},
        {'latency_sum', 18, {tag = 'a'}},
        {'latency', 5, {quantile = 0.5, tag = 'a'}},
        {'latency', 6, {quantile = 0.9, tag = 'a'}},
        {'latency', 6, {quantile = 0.99, tag = 'a'}},
        {'latency_count', 1, {tag = 'b'}},
        {'latency_sum', 6, {tag = 'b'}},
        {'latency', 6, {quantile = 0.5, tag = 'b'}},
        {'latency', 6, {quantile = 0.9, tag = 'b'}},
        {'latency', 6, {quantile = 0.99, tag = 'b'}},
    })
end

g.test_collect_10k = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local sum = 0
    for i = 1, 10^4 do
        instance:observe(i)
        sum = sum + i
    end
    local res = utils.observations_without_timestamps(instance:collect())
    t.assert_items_equals(res[1], {
        label_pairs = {},
        metric_name = "latency_count",
        value = 10^4,
    })
    t.assert_items_equals(res[2], {
        label_pairs = {},
        metric_name = "latency_sum",
        value = sum,
    })
end
