local log = require('log')

local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')

local INF = math.huge
local DEFAULT_BUCKETS = {.005, .01, .025, .05, .075, .1, .25, .5,
                         .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}

local Histogram = Shared:new_class('histogram', {'observe', 'observe_latency'})

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

function Histogram:new(name, help, buckets, metainfo, label_keys)
    metainfo = table.copy(metainfo) or {}
    local obj = Shared.new(self, name, help, metainfo, label_keys)

    obj.buckets = buckets or DEFAULT_BUCKETS
    table.sort(obj.buckets)
    if obj.buckets[#obj.buckets] ~= INF then
        obj.buckets[#obj.buckets+1] = INF
    end

    obj.count_collector = Counter:new(name .. '_count', help, metainfo, label_keys)
    obj.sum_collector = Counter:new(name .. '_sum', help, metainfo, label_keys)

    local bkt_label_keys = table.copy(label_keys)
    if bkt_label_keys ~= nil then
        table.insert(bkt_label_keys, 'le')
    end

    obj.bucket_collector = Counter:new(name .. '_bucket', help, metainfo, bkt_label_keys)

    return obj
end

function Histogram:set_registry(registry)
    Shared.set_registry(self, registry)
    self.count_collector:set_registry(registry)
    self.sum_collector:set_registry(registry)
    self.bucket_collector:set_registry(registry)
end

function Histogram:prepare(label_pairs)
    local buckets_prepared = table.new(0, #self.buckets)
    for _, bucket in ipairs(self.buckets) do
        local bkt_label_pairs = table.deepcopy(label_pairs) or {}
        if type(bkt_label_pairs) == 'table' then
            bkt_label_pairs.le = bucket
        end

        buckets_prepared[bucket] = Counter.Prepared:new(self.bucket_collector, bkt_label_pairs)
    end

    local prepared = Histogram.Prepared:new(self, label_pairs)
    prepared.count_prepared = Counter.Prepared:new(self.count_collector, label_pairs)
    prepared.sum_prepared = Counter.Prepared:new(self.sum_collector, label_pairs)
    prepared.buckets_prepared = buckets_prepared

    return prepared
end

local cdata_warning_logged = false

function Histogram.Prepared:observe(num)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Histogram observation should be a number")
    end
    if not cdata_warning_logged and type(num) == 'cdata' then
        log.error("Using cdata as observation in historgam " ..
            "can lead to unexpected results. " ..
            "That log message will be an error in the future.")
        cdata_warning_logged = true
    end

    self.count_prepared:inc(1)
    self.sum_prepared:inc(num)

    for bucket, bucket_prepared in pairs(self.buckets_prepared) do
        if num <= bucket then
            bucket_prepared:inc(1)
        else
            -- all buckets are needed for histogram quantile approximation
            -- this creates buckets if they were not created before
            bucket_prepared:inc(0)
        end
    end
end

function Histogram.Prepared:remove()
    self.count_prepared:remove()
    self.sum_prepared:remove()

    for _, bucket_prepared in pairs(self.buckets_prepared) do
        bucket_prepared:remove()
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
