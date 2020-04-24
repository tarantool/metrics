local fiber = require('fiber')

local Shared = require('metrics.collectors.shared')

--- Collector to produce count and average value metrics.
-- Average value is is calculated between two subsequent `:collect` calls.
local Average = Shared:new_class('average')

function Average:new(name, help)
    local obj = Shared.new(self, name, help)
    obj.count_name = name .. '_count'
    obj.avg_name = name .. '_avg'
    return obj
end

function Average:observe(value, label_pairs)
    label_pairs = label_pairs or {}
    local key = self.make_key(label_pairs)
    local observation = self.observations[key]
    if observation then
        observation[2] = observation[2] + 1
        observation[3] = observation[3] + value
    else
        self.observations[key] = {
            label_pairs,
            1, -- count
            value, -- sum
            0, -- last count
            0, -- last sum
        }
    end
end

function Average:collect()
    local now = fiber.time64()
    local result = {}
    for _, observation in pairs(self.observations) do
        local label_pairs, count, sum = observation[1], observation[2], observation[3]
        label_pairs = self:append_global_labels(label_pairs)
        table.insert(result, {
            metric_name = self.count_name,
            label_pairs = label_pairs,
            value = count,
            timestamp = now,
        })
        local last_count, last_sum = observation[4], observation[5]
        observation[4] = count
        observation[5] = sum
        local diff = count - last_count
        table.insert(result, {
            metric_name = self.avg_name,
            label_pairs = label_pairs,
            value = diff > 0 and ((sum - last_sum) / diff) or 0,
            timestamp = now,
        })
    end
    return result
end

return Average
