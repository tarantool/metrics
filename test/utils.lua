local t = require('luatest')

local fun = require('fun')
local metrics = require('metrics')

local utils = {}

function utils.find_obs(metric_name, label_pairs, observations)
    for _, obs in pairs(observations) do
        local same_label_pairs = pcall(t.assert_equals, obs.label_pairs, label_pairs)
        if obs.metric_name == metric_name and same_label_pairs then
            return obs
        end
    end
    t.fail("haven't found observation")
end

function utils.observations_without_timestamps(observations)
    return fun.iter(observations or metrics.collect()):
        map(function(x)
            x.timestamp = nil
            return x
        end):
        totable()
end

function utils.assert_observations(actual, expected)
    t.assert_items_equals(
        utils.observations_without_timestamps(actual),
        fun.iter(expected):map(function(x)
            return {
                metric_name = x[1],
                value = x[2],
                label_pairs = x[3],
            }
        end):totable()
    )
end

return utils
