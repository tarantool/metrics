local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')

local INF = math.huge
local DEFAULT_BUCKETS = {.005, .01, .025, .05, .075, .1, .25, .5,
                         .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}

local Histogram = Shared:new_class('histogram', {'observe_latency'})

function Histogram.check_buckets(buckets)
    local prev = -math.huge
    for k, v in pairs(buckets) do
        if type(k) ~= 'number' then return false end
        if type(v) ~= 'number' then return false end
        if v <= 0 then return false end
        if prev > v then return false end
        prev = v
    end
    return true
end

function Histogram:new(name, help, buckets)
    local obj = Shared.new(self, name, help)

    obj.buckets = buckets or DEFAULT_BUCKETS
    table.sort(obj.buckets)
    if obj.buckets[#obj.buckets] ~= INF then
        obj.buckets[#obj.buckets+1] = INF
    end

    obj.count_collector = Counter:new(name .. '_count', help)
    obj.sum_collector = Counter:new(name .. '_sum', help)
    obj.bucket_collector = Counter:new(name .. '_bucket', help)

    return obj
end

function Histogram:set_registry(registry)
    Shared.set_registry(self, registry)
    self.count_collector:set_registry(registry)
    self.sum_collector:set_registry(registry)
    self.bucket_collector:set_registry(registry)
end

function Histogram:observe(num, label_pairs)
    label_pairs = label_pairs or {}

    self.count_collector:inc(1, label_pairs)
    self.sum_collector:inc(num, label_pairs)

    for _, bucket in pairs(self.buckets) do
        local bkt_label_pairs = table.deepcopy(label_pairs)
        bkt_label_pairs.le = bucket

        if num <= bucket then
            self.bucket_collector:inc(1, bkt_label_pairs)
        else
            -- all buckets are needed for histogram quantile approximation
            -- this creates buckets if they were not created before
            self.bucket_collector:inc(0, bkt_label_pairs)
        end
    end
end

function Histogram:collect()
    local result = {}
    for _, obs in pairs(self.count_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in pairs(self.sum_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in pairs(self.bucket_collector:collect()) do
        table.insert(result, obs)
    end
    return result
end

return Histogram
