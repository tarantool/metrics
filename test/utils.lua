local t = require('luatest')

local utils = {}

-- a < b
local function subset_of(a, b)
    for name, value in pairs(a) do
        if b[name] ~= value then
            return false
        end
    end
    return true
end

-- a = b
local function equal_sets(a, b)
    return subset_of(a, b) and subset_of(b, a)
end

function utils.find_obs(metric_name, label_pairs, observations)
    for _, obs in pairs(observations) do
        local same_label_pairs = equal_sets(obs.label_pairs, label_pairs)
        if obs.metric_name == metric_name and same_label_pairs then
            return obs
        end
    end
    t.fail("haven't found observation")
end

return utils