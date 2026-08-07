local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')
local Quantile = require('metrics.quantile')

local fiber = require('fiber')

---@class metrics.collector.summary : metrics.collector
---@field count_collector metrics.collector.counter
---@field sum_collector metrics.collector.counter
---@field objectives table<number, number>|nil
---@field quantiles number[]|nil
---@field max_age_time number|nil
---@field age_buckets_count number
---@field observations table<string, table>
local Summary = Shared:new_class('summary', {'observe_latency'})

---@param name string
---@param help string?
---@param objectives table<number, number>?
---@param params {age_buckets_count?: number, max_age_time?: number}?
---@param metainfo metrics.metainfo?
---@return metrics.collector.summary
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
        for q, _ in pairs(obj.objectives) do
            table.insert(obj.quantiles, q)
        end
    end
    return obj
end

---@param objectives table<number, number>
---@return boolean
function Summary.check_quantiles(objectives)
    for k, v in pairs(objectives) do
        if type(k) ~= 'number' then return false end
        if k > 1 or k < 0 then return false end
        if type(v) ~= 'number' then return false end
    end
    return true
end

---@param registry metrics.registry
function Summary:set_registry(registry)
    Shared.set_registry(self, registry)
    self.count_collector:set_registry(registry)
    self.sum_collector:set_registry(registry)
end

---@param key string
function Summary:rotate_age_buckets(key)
    --- @type any
    local obs_object = self.observations[key]
    local old_index = obs_object.head_bucket_index
    obs_object.head_bucket_index = ((obs_object.head_bucket_index + 1) % self.age_buckets_count) + 1
    Quantile.Reset(obs_object.buckets[old_index])
    obs_object.last_rotate = os.time()
end

--- Record a new value in a summary.
---@param num number
---@param label_pairs metrics.label_pairs?
function Summary:observe(num, label_pairs)
    label_pairs = label_pairs or {}
    ---@diagnostic disable-next-line: unnecessary-if
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

--- Remove the observation for `label_pairs`.
---@param label_pairs metrics.label_pairs?
function Summary:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    self.count_collector:remove(label_pairs)
    self.sum_collector:remove(label_pairs)
    if self.objectives then
        local key = self.make_key(label_pairs)
        self.observations[key] = nil
    end
end

---@return metrics.observation[]
function Summary:collect_quantiles()
    local quantiles = self.quantiles
    if not self.objectives or not quantiles or next(self.observations) == nil then
        return {}
    end

    local result = {}
    local now = os.time()
    for key, observation in pairs(self.observations) do
        if self.age_buckets_count > 1 and now - observation.last_rotate >= self.max_age_time then
            self:rotate_age_buckets(key)
        end
        for _, objective in ipairs(quantiles) do
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

--- Return observations from all internal counters.
---@return metrics.observation[]
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
---@param label_pairs metrics.label_pairs?
---@return table|any
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
