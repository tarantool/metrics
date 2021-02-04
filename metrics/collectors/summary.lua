local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')
local Quantile = require('metrics.quantile')

local fiber = require('fiber')

local Summary = Shared:new_class('summary', {'observe_latency'})

function Summary:new(name, help, objectives, max_age, age_buckets)
    local obj = Shared.new(self, name, help)

    obj.count_collector = Counter:new(name .. '_count', help)
    obj.sum_collector = Counter:new(name .. '_sum', help)
    obj.objectives = objectives
    obj.max_age = max_age
    obj.age_buckets = age_buckets or 0
    obj.age_buckets_obs = {}
    obj.last_rotate = {}
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

function Summary:rotate_age_buckets(key)
    self.observations[key] = self.age_buckets_obs[key][1]
    for i = 2, self.age_buckets do
        self.age_buckets_obs[key][i - 1] = self.age_buckets_obs[key][i]
    end
    self.age_buckets_obs[key][self.age_buckets] = Quantile.NewTargeted(self.objectives)
    self.last_rotate[key] = os.time()
end

function Summary:observe(num, label_pairs)
    label_pairs = label_pairs or {}
    if label_pairs.quantile then
        error('Label "quantile" are not allowed in summary')
    end
    self.count_collector:inc(1, label_pairs)
    self.sum_collector:inc(num, label_pairs)
    if self.objectives then
        local key = self.make_key(label_pairs)
        if not self.observations[key] then
            self.observations[key] = Quantile.NewTargeted(self.objectives)
            self.age_buckets_obs[key] = self.age_buckets and {}
            for i = 1, self.age_buckets do
                self.age_buckets_obs[key][i] = Quantile.NewTargeted(self.objectives)
            end
            self.label_pairs[key] = label_pairs
            self.last_rotate[key] = os.time()
        end
        Quantile.Insert(self.observations[key], num)
        for i = 1, self.age_buckets do
            Quantile.Insert(self.age_buckets_obs[key][i], num)
        end
        if self.age_buckets > 0 and os.time() - self.last_rotate[key] >= self.max_age then
            self:rotate_age_buckets(key)
        end
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
