local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')
local Gauge = require('metrics.collectors.gauge')
local Quantile = require('metrics.quantile')

local fiber = require('fiber')
-- MAX_AGE is the default duration for which observations stay
-- relevant.
MAX_AGE = 10 * 60
-- AGE_BUCKETS is the default number of buckets used to calculate the
-- age of observations.
AGE_BUCKETS = 5

local Summary = Shared:new_class('summary', {'observe_latency'})

function Summary:new(name, help, objectives)
    local obj = Shared.new(self, name, help)

    obj.count_collector = Counter:new(name .. '_count', help)
    obj.sum_collector = Counter:new(name .. '_sum', help)

    if objectives then
        obj.objectives = objectives
        obj.quantile_collector = Gauge:new(name, help)
        obj.streams = {}
        for i = 1, AGE_BUCKETS do
            obj.streams[i] = Quantile.NewTargeted(objectives)
        end
        obj.head_stream_idx = 1
        obj.head_stream = obj.streams[obj.head_stream_idx]
        obj.stream_dur = MAX_AGE / AGE_BUCKETS
        obj.exp_time = fiber.time() + obj.stream_dur
    end

    return obj
end

function Summary:set_registry(registry)
    Shared.set_registry(self, registry)
    self.count_collector:set_registry(registry)
    self.sum_collector:set_registry(registry)
    if self.objectives then
        self.quantile_collector:set_registry(registry)
    end
end

function Summary:maybe_rotate_streams()
    local now = fiber.time()
    if now > self.exp_time then
		Quantile.Reset(self.head_stream)
		self.head_stream_idx = self.head_stream_idx + 1
		if self.head_stream_idx > #self.streams then
			self.head_stream_idx = 1
        end
		self.head_stream = self.streams[self.head_stream_idx]
		self.exp_time = self.exp_time + self.stream_dur
	end
end

function Summary:observe(num, label_pairs)
    label_pairs = label_pairs or {}

    self.count_collector:inc(1, label_pairs)
    self.sum_collector:inc(num, label_pairs)

    if self.objectives then
        for _, stream in ipairs(self.streams) do
            Quantile.Insert(stream, num)
        end
    end
    for objective, _ in pairs(self.objectives) do
        local objective_label_pairs = table.deepcopy(label_pairs)
        objective_label_pairs.quantile = objective
        local q = Quantile.Query(self.head_stream, objective)
        self.quantile_collector:set(q, objective_label_pairs)
    end
    self:maybe_rotate_streams()
end

function Summary:collect()
    local result = {}
    for _, obs in pairs(self.count_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in pairs(self.sum_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in pairs(self.quantile_collector:collect()) do
        table.insert(result, obs)
    end
    return result
end

return Summary
