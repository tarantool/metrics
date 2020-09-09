local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')
local Quantile = require('metrics.quantile')

local fiber = require('fiber')

local Summary = Shared:new_class('summary', {'observe_latency'})

function Summary:new(name, help, objectives)
    local obj = Shared.new(self, name, help)

    obj.count_collector = Counter:new(name .. '_count', help)
    obj.sum_collector = Counter:new(name .. '_sum', help)
    obj.objectives = objectives

    return obj
end

function Summary.check_quantiles(objectives)
    for k, v in pairs(objectives) do
        if type(k) ~= 'number' then return false end
        if k >= 1 or k < 0 then return false end
        if type(v) ~= 'number' then return false end
    end
    return true
end

function Summary:set_registry(registry)
    Shared.set_registry(self, registry)
    self.count_collector:set_registry(registry)
    self.sum_collector:set_registry(registry)
end

function Summary:observe(num, label_pairs)
    label_pairs = label_pairs or {}

    self.count_collector:inc(1, label_pairs)
    self.sum_collector:inc(num, label_pairs)
    if self.objectives then
        local key = self.make_key(label_pairs)
        if not self.observations[key] then
            self.observations[key] = Quantile.NewTargeted(self.objectives)
            self.label_pairs[key] = label_pairs
        end
        Quantile.Insert(self.observations[key], num)
    end
end


function Summary:collect_quantiles()
    if next(self.observations) == nil then
        return {}
    end
    local result = {}
    for key, observation in pairs(self.observations) do
        for objective, _ in pairs(self.objectives) do
            local label_pairs = table.deepcopy(self:append_global_labels(self.label_pairs[key]))
            label_pairs.quantile = objective
            local obs = {
                metric_name = self.name,
                label_pairs = label_pairs,
                value = Quantile.Query(observation, objective),
                timestamp = fiber.time64(),
            }
            table.insert(result, obs)
        end
    end
    return result
end

function Summary:collect()
    local result = {}
    for _, obs in pairs(self.count_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in pairs(self.sum_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in pairs(self:collect_quantiles()) do
        table.insert(result, obs)
    end
    return result
end

return Summary
