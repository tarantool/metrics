local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')
local Quantile = require('metrics.quantile')

local fiber = require('fiber')

local Summary = Shared:new_class('summary', {'observe_latency'})

function Summary:new(name, help, objectives, params, metainfo)
    params = params or {}
    metainfo = table.copy(metainfo) or {}
    local obj = Shared.new(self, name, help, metainfo)

    obj.count_collector = Counter:new(name .. '_count', help, metainfo)
    obj.sum_collector = Counter:new(name .. '_sum', help, metainfo)
    obj.objectives = objectives
    obj.max_age_time = params.max_age_time
    obj.age_buckets_count = params.age_buckets_count or 1
    obj.observations = {}

    if obj.objectives then
        obj.quantiles = {}
        for q, _ in pairs(objectives) do
            table.insert(obj.quantiles, q)
        end
    end
    return obj
end

function Summary.check_quantiles(objectives)
    for k, v in pairs(objectives) do
        if type(k) ~= 'number' then return false end
        if k > 1 or k < 0 then return false end
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
    local obs_object = self.observations[key]
    local old_index = obs_object.head_bucket_index
    obs_object.head_bucket_index = ((obs_object.head_bucket_index + 1) % self.age_buckets_count) + 1
    Quantile.Reset(obs_object.buckets[old_index])
    obs_object.last_rotate = os.time()
end

function Summary:observe(num, label_pairs)
    label_pairs = label_pairs or {}
    if label_pairs.quantile then
        error('Label "quantile" are not allowed in summary')
    end
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Summary observation should be a number")
    end
    self.count_collector:inc(1, label_pairs)
    self.sum_collector:inc(num, label_pairs)
    if self.objectives then
        local now = os.time()
        local key = self.make_key(label_pairs)

        if not self.observations[key] then
            local obs_object = {
                buckets = {},
                head_bucket_index = 1,
                last_rotate = now,
                label_pairs = label_pairs,
            }
            self.label_pairs[key] = label_pairs
            for i = 1, self.age_buckets_count do
                local quantile_obj = Quantile.NewTargeted(self.objectives)
                Quantile.Insert(quantile_obj, num)
                obs_object.buckets[i] = quantile_obj
            end
            self.observations[key] = obs_object
        else
            local obs_object = self.observations[key]
            if self.age_buckets_count > 1 and now - obs_object.last_rotate >= self.max_age_time then
                self:rotate_age_buckets(key)
            end
            for _, bucket in ipairs(obs_object.buckets) do
                Quantile.Insert(bucket, num)
            end
        end
    end
end

function Summary:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    self.count_collector:remove(label_pairs)
    self.sum_collector:remove(label_pairs)
    if self.objectives then
        local key = self.make_key(label_pairs)
        self.observations[key] = nil
    end
end

function Summary:collect_quantiles()
    if not self.objectives or next(self.observations) == nil then
        return {}
    end

    local result = {}
    local now = os.time()
    for key, observation in pairs(self.observations) do
        if self.age_buckets_count > 1 and now - observation.last_rotate >= self.max_age_time then
            self:rotate_age_buckets(key)
        end
        for _, objective in ipairs(self.quantiles) do
            local label_pairs = table.deepcopy(self:append_global_labels(observation.label_pairs))
            label_pairs.quantile = objective
            local obs = {
                metric_name = self.name,
                label_pairs = label_pairs,
                value = Quantile.Query(observation.buckets[observation.head_bucket_index], objective),
                timestamp = fiber.time64(),
            }
            table.insert(result, obs)
        end
    end
    return result
end

function Summary:collect()
    local result = {}
    for _, obs in ipairs(self.count_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in ipairs(self.sum_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in ipairs(self:collect_quantiles()) do
        table.insert(result, obs)
    end
    return result
end

-- debug function to get observation quantiles from summary
-- returns array of quantile objects or
-- single quantile object if summary has only one bucket
function Summary:get_observations(label_pairs)
    local key = self.make_key(label_pairs or {})
    local obs = self.observations[key]
    if self.age_buckets_count > 1 then
        return obs
    else
        return obs.buckets[1]
    end
end

return Summary
