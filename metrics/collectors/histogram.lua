local fiber = require('fiber')

local string_utils = require('metrics.string_utils')

local Shared = require('metrics.collectors.shared')
local Counter = require('metrics.collectors.counter')

local INF = math.huge
local DEFAULT_BUCKETS = {.005, .01, .025, .05, .075, .1, .25, .5,
                         .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}

local Histogram = Shared:new_class('histogram', {'observe_latency'})
Histogram.COUNT_SUFFIX = 'count'
Histogram.SUM_SUFFIX = 'sum'
Histogram.BUCKET_SUFFIX = 'bucket'

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
    metainfo = table.copy(metainfo) or {}
    local obj = Shared.new(self, name, help, metainfo)

    obj.buckets = buckets or DEFAULT_BUCKETS
    table.sort(obj.buckets)
    if obj.buckets[#obj.buckets] ~= INF then
        obj.buckets[#obj.buckets+1] = INF
    end

    obj.count_collector = Counter:new(
        string_utils.build_name(name, Histogram.COUNT_SUFFIX),
        help, metainfo)
    obj.sum_collector = Counter:new(
        string_utils.build_name(name, Histogram.SUM_SUFFIX),
        help, metainfo)
    obj.bucket_collector = Counter:new(
        string_utils.build_name(name, Histogram.BUCKET_SUFFIX),
        help, metainfo)

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
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Histogram observation should be a number")
    end

    self.count_collector:inc(1, label_pairs)
    self.sum_collector:inc(num, label_pairs)

    for _, bucket in ipairs(self.buckets) do
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

function Histogram:_collect_v1_implementation()
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

function Histogram._collect_v2_observations()
    error("Not supported for complex collectors")
end

function Histogram:_collect_v2_implementation()
    return {
        name = self.name,
        name_prefix = self.name_prefix,
        kind = self.kind,
        help = self.help,
        metainfo = self.metainfo,
        timestamp = fiber.time64(),
        observations = {
            [Histogram.COUNT_SUFFIX] = self.count_collector:_collect_v2_observations(),
            [Histogram.SUM_SUFFIX] = self.sum_collector:_collect_v2_observations(),
            [Histogram.BUCKET_SUFFIX] = self.bucket_collector:_collect_v2_observations(),
        }
    }
end

return Histogram
