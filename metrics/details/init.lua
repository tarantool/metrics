-- vim: ts=4:sw=4:sts=4:expandtab
-- luacheck: globals box

local fiber = require('fiber')

local INF = math.huge
local NAN = math.huge * 0
local DEFAULT_BUCKETS = {.005, .01, .025, .05, .075, .1, .25, .5,
                         .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}

local Registry = {}
Registry.__index = Registry

function Registry.new()
    local obj = {}
    setmetatable(obj, Registry)

    obj.collectors = {}
    obj.callbacks = {}
    return obj
end

function Registry:register(collector)
    for _, c in ipairs(self.collectors) do
        if c.name == collector.name and c.kind == collector.kind then
            return
        end
    end
    table.insert(self.collectors, collector)
end

function Registry:unregister(collector)
    for i, c in ipairs(self.collectors) do
        if c.name == collector.name and c.kind == collector.kind then
            table.remove(self.collectors, i)
        end
    end
end

function Registry:collect()
    for _, registered_callback in ipairs(self.callbacks) do
        registered_callback()
    end

    local result = {}
    for _, collector in pairs(self.collectors) do
        for _, obs in ipairs(collector:collect()) do
            table.insert(result, obs)
        end
    end
    return result
end

function Registry:register_callback(callback)
    local found = false
    for _, registered_callback in ipairs(self.callbacks) do
        if registered_callback == callback then
            found = true
        end
    end
    if not found then
        table.insert(self.callbacks, callback)
    end
end

global_metrics_registry = Registry.new()

------------------------------- Common Methods -------------------------------

local Shared = {}

function Shared.new(name, help, kind)
    if not name then
        error("Name should be set for %s", kind)
    end

    local obj = {}
    obj.name = name
    obj.help = help or ""
    obj.observations = {}
    obj.label_pairs = {}
    obj.kind = kind

    return obj
end

local function make_key(label_pairs)
    local key = ''
    for k, v in pairs(label_pairs) do
        key = key .. k .. '\t' .. v .. '\t'
    end
    return key
end

function Shared:set(num, label_pairs)
    local num = num or 0
    local label_pairs = label_pairs or {}
    local key = make_key(label_pairs)
    self.observations[key] = num
    self.label_pairs[key] = label_pairs
end

function Shared:inc(num, label_pairs)
    local num = num or 1
    local label_pairs = label_pairs or {}
    local key = make_key(label_pairs)
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value + num
    self.label_pairs[key] = label_pairs
end

function Shared:dec(num, label_pairs)
    local num = num or 1
    local label_pairs = label_pairs or {}
    local key = make_key(label_pairs)
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value - num
    self.label_pairs[key] = label_pairs
end

function Shared:collect()
    if next(self.observations) == nil then
        return {}
    end
    local result = {}
    for key, observation in pairs(self.observations) do
        local obs = {
            metric_name = self.name,
            label_pairs = self.label_pairs[key],
            value = observation,
            timestamp = fiber.time64(),
        }
        table.insert(result, obs)
    end
    return result
end

-------------------------------- Collectors ----------------------------------

local Counter = {}
Counter.__index = Counter

function Counter.new(name, help, opts)
    local opts = opts or {}
    opts.do_register = opts.do_register or true

    local obj = Shared.new(name, help, 'counter')
    if opts.do_register then
        global_metrics_registry:register(obj)
    end

    return setmetatable(obj, Counter)
end

function Counter:inc(num, label_pairs)
    if num and num < 0 then
        error("Counter increment should not be negative")
    end
    Shared.inc(self, num, label_pairs)
end

function Counter:collect()
    return Shared.collect(self)
end

local Gauge = {}
Gauge.__index = Gauge

function Gauge.new(name, help)
    local obj = Shared.new(name, help, 'gauge')
    global_metrics_registry:register(obj)

    return setmetatable(obj, Gauge)
end

function Gauge:inc(num, label_pairs)
    Shared.inc(self, num, label_pairs)
end

function Gauge:dec(num, label_pairs)
    Shared.dec(self, num, label_pairs)
end

function Gauge:set(num, label_pairs)
    Shared.set(self, num, label_pairs)
end

function Gauge:collect()
    return Shared.collect(self)
end

local Histogram = {}
Histogram.__index = Histogram

function Histogram.new(name, help, buckets)
    local obj = {}

    -- for registry
    obj.name = name
    obj.help = help or ''
    obj.kind = 'histogram'

    -- introduce buckets
    obj.buckets = buckets or DEFAULT_BUCKETS
    table.sort(obj.buckets)
    if obj.buckets[#obj.buckets] ~= INF then
        obj.buckets[#obj.buckets+1] = INF
    end

    -- create counters
    obj.count_collector = Counter.new(
        name .. '_count', help, {do_register = false}
    )
    obj.sum_collector = Counter.new(
        name .. '_sum', help, {do_register = false}
    )
    obj.bucket_collector = Counter.new(
        name .. '_bucket', help, {do_register = false}
    )

    -- register
    global_metrics_registry:register(obj)

    return setmetatable(obj, Histogram)
end

function Histogram:observe(num, label_pairs)
    local label_pairs = label_pairs or {}

    self.count_collector:inc(1, label_pairs)
    self.sum_collector:inc(num, label_pairs)

    for _, bucket in pairs(self.buckets) do
        local bkt_label_pairs = table.deepcopy(label_pairs) -- luacheck: ignore
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

return {
    INF = INF,
    NAN = NAN,

    Counter = Counter,
    Gauge = Gauge,
    Histogram = Histogram,
}
