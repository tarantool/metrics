local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')

local INF = math.huge
local DEFAULT_BUCKETS = {.005, .01, .025, .05, .075, .1, .25, .5,
                         .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}

local Histogram = Shared:new_class('histogram', {'observe_latency'})

function Histogram.check_buckets(buckets)
    local prev = -math.huge
    for _, v in ipairs(buckets) do
        if type(v) ~= 'number' then return false end
        if v <= 0 then return false end
        if prev > v then return false end
        prev = v
    end
    return true
end

function Histogram:new(name, help, buckets, metainfo)
    metainfo = table.deepcopy(metainfo) or {}
    local obj = Shared.new(self, name, help, metainfo)
    obj.buckets = buckets or DEFAULT_BUCKETS
    table.sort(obj.buckets)
    if obj.buckets[#obj.buckets] ~= INF then
        obj.buckets[#obj.buckets+1] = INF
    end
    obj.count_collector = Counter:new(name .. '_count', help, metainfo)
    obj.sum_collector = Counter:new(name .. '_sum', help, metainfo)
    obj.bucket_collector = Counter:new(name .. '_bucket', help, metainfo)
    -- metrics.registry:register(hist)
    return obj
end

function Histogram:set_registry(registry)
    Shared.set_registry(self, registry)
    self.count_collector:set_registry(registry)
    self.sum_collector:set_registry(registry)
    self.bucket_collector:set_registry(registry)
end

local function memoize(func)
    local cache = {}
    return function(key)
        if key == nil then
            return ""
        end
        local value = cache[key]
        if value then
            return value
        end
        value = func(key)
        cache[key] = value
        return value
    end
end

Histogram.make_key = memoize(function(label_pairs)
    if type(label_pairs) ~= 'table' then
        return ""
    end
    local parts = {}
    for k, v in pairs(label_pairs) do
        table.insert(parts, k .. '\t' .. v)
    end
    table.sort(parts)
    local result = table.concat(parts, '\t')
    return result
end)

local empty_tbl = {}

function Histogram:observe(num, label_pairs)
    -- we need to increment by 1 bucket < num and by 0 bucket > num
    local key = self.make_key(label_pairs)
    local count_collector = self.count_collector
    if not count_collector.observations[key] then
        count_collector.observations[key] = (count_collector.observations[key] or 0) + 1
        count_collector.label_pairs[key] = label_pairs or empty_tbl
    else
        count_collector.observations[key] = count_collector.observations[key] + 1
    end
    local sum_collector = self.sum_collector
    if not sum_collector.observations[key] then
        sum_collector.observations[key] = (sum_collector.observations[key] or 0) + num
        sum_collector.label_pairs[key] = label_pairs or empty_tbl
    else
        sum_collector.observations[key] = sum_collector.observations[key] + num
    end
    local bucket_collector = self.bucket_collector
    for _, bucket in ipairs(self.buckets) do
        local inc = num <= bucket and 1 or 0
        local bucket_key = key .. 'le\t'..bucket
        -- implicitely create labels if they not exists
        if not bucket_collector.observations[bucket_key] then
                    bucket_collector.observations[bucket_key] = inc
        local bucket_label_pairs
        if not label_pairs then
            bucket_label_pairs = {le=bucket}
        else
            bucket_label_pairs = table.deepcopy(label_pairs)
            bucket_label_pairs.le = bucket
        end
            bucket_collector.label_pairs[bucket_key] = bucket_label_pairs
        -- increment only when need to
        elseif inc == 1 then
            bucket_collector.observations[bucket_key] = bucket_collector.observations[bucket_key] + inc
        end
    end
end

function Histogram:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    self.count_collector:remove(label_pairs)
    self.sum_collector:remove(label_pairs)

    for _, bucket in ipairs(self.buckets) do
        local bkt_label_pairs = table.deepcopy(label_pairs)
        bkt_label_pairs.le = bucket
        self.bucket_collector:remove(bkt_label_pairs)
    end
end

function Histogram:collect()
    local result = {}
    for _, obs in ipairs(self.count_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in ipairs(self.sum_collector:collect()) do
        table.insert(result, obs)
    end
    for _, obs in ipairs(self.bucket_collector:collect()) do
        table.insert(result, obs)
    end
    return result
end

return Histogram
