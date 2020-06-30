local fiber = require('fiber')

local Shared = require('metrics.collectors.shared')

--- Collector to produce count and average value metrics.
-- Average value is is calculated between two subsequent `:collect` calls.
local Average = Shared:new_class('average', {'observe_latency'})

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
        observation.count = observation.count + 1
        observation.sum = observation.sum + value
    else
        self.observations[key] = {
            label_pairs = label_pairs,
            count = 1,
            sum = value,
            last_count = 0,
            last_sum = 0,
        }
    end
end

function Average:collect()
    local now = fiber.time64()
    local result = {}
    for _, observation in pairs(self.observations) do
        local label_pairs = self:append_global_labels(observation.label_pairs)
        table.insert(result, {
            metric_name = self.count_name,
            label_pairs = label_pairs,
            value = observation.count,
            timestamp = now,
        })
        local diff = observation.count - observation.last_count
        local average = diff > 0 and ((observation.sum - observation.last_sum) / diff) or 0
        table.insert(result, {
            metric_name = self.avg_name,
            label_pairs = label_pairs,
            value = average,
            timestamp = now,
        })
        observation.last_count = observation.count
        observation.last_sum = observation.sum
    end
    return result
end

return Average
