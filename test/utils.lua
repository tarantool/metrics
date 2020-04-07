local t = require('luatest')

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

return utils
