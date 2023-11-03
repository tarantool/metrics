-- vim: ts=4:sw=4:sts=4:expandtab

local checks = require('checks')

local Registry = require('metrics.registry')

local Counter = require('metrics.collectors.counter')
local Gauge = require('metrics.collectors.gauge')
local Histogram = require('metrics.collectors.histogram')
local Summary = require('metrics.collectors.summary')

local registry = rawget(_G, '__metrics_registry')
if not registry then
    registry = Registry.new()
end
registry.callbacks = {}

rawset(_G, '__metrics_registry', registry)

local function collectors()
    return registry.collectors
end

local function register_callback(...)
    return registry:register_callback(...)
end

local function unregister_callback(...)
    return registry:unregister_callback(...)
end

local function invoke_callbacks()
    return registry:invoke_callbacks()
end

local function get_collector_values(collector, result)
    for _, obs in ipairs(collector:collect()) do
        table.insert(result, obs)
    end
end

local function collect(opts)
    checks({invoke_callbacks = '?boolean', default_only = '?boolean'})
    opts = opts or {}

    if opts.invoke_callbacks then
        registry:invoke_callbacks()
    end

    local result = {}
    for _, collector in pairs(registry.collectors) do
        if opts.default_only then
            if collector.metainfo.default then
                get_collector_values(collector, result)
            end
        else
            get_collector_values(collector, result)
        end
    end

    return result
end

local function clear()
    registry:clear()
end

local function counter(name, help, metainfo)
    checks('string', '?string', '?table')

    return registry:find_or_create(Counter, name, help, metainfo)
end

local function gauge(name, help, metainfo)
    checks('string', '?string', '?table')

    return registry:find_or_create(Gauge, name, help, metainfo)
end

local function histogram(name, help, buckets, metainfo)
    checks('string', '?string', '?table', '?table')
    if buckets ~= nil and not Histogram.check_buckets(buckets) then
        error('Invalid value for buckets')
    end

    return registry:find_or_create(Histogram, name, help, buckets, metainfo)
end

local function summary(name, help, objectives, params, metainfo)
    checks('string', '?string', '?table', {
        age_buckets_count = '?number',
        max_age_time = '?number',
    }, '?table')
    if objectives ~= nil and not Summary.check_quantiles(objectives) then
        error('Invalid value for objectives')
    end
    params = params or {}
    local age_buckets_count = params.age_buckets_count
    local max_age_time = params.max_age_time
    if max_age_time and max_age_time <= 0 then
        error('Max age must be positive')
    end
    if age_buckets_count and age_buckets_count < 1 then
        error('Age buckets count must be greater or equal than one')
    end
    if (max_age_time and not age_buckets_count) or (not max_age_time and age_buckets_count) then
        error('Age buckets count and max age must be present only together')
    end

    return registry:find_or_create(Summary, name, help, objectives, params, metainfo)
end

local function set_global_labels(label_pairs)
    checks('?table')

    label_pairs = label_pairs or {}

    -- Verify label table
    for k, _ in pairs(label_pairs) do
        if type(k) ~= 'string' then
            error(("bad label key (string expected, got %s)"):format(type(k)))
        end
    end

    registry:set_labels(label_pairs)
end

--- Prepares a serializer for label pairs with given keys.
---
--- `make_key`, which is used during every metric-related operation, is not very efficient itself.
--- To mitigate it, one could add his own serialization implementation.
--- It is done via passing `__metrics_make_key` callback to the label pairs table.
---
--- This function gives you ready-to-use serializer, so you don't have to create one yourself.
---
--- BEWARE! If keys of the `label_pairs` somehow change between serialization turns, it would raise error mostlikely.
--- Therefore, it's important to understand full scope of needed fields. For instance, for histogram:observe,
--- an additional label 'le' is always needed.
---
--- @class LabelsSerializer
--- @field wrap function(label_pairs: table): table Wraps given `label_pairs` with an efficient serialization.
--- @field serialize function(label_pairs: table): string Serialize given `label_pairs` into the key.
--- Exposed so you can write your own serializers on top of it.
---
--- @param labels_keys string[] Label keys for the further use.
--- @return LabelsSerializer
local function labels_serializer(labels_keys)
    table.sort(labels_keys)

    -- used to protect label_pairs from altering with unexpected keys.
    local keys_index = {}
    for _, key in ipairs(labels_keys) do
        keys_index[key] = true
    end

    local function serialize(label_pairs)
        local result = ""
        for _, label in ipairs(labels_keys) do
            local value = label_pairs[label]
            if value ~= nil then
                if result ~= "" then
                    result = result .. '\t'
                end
                result = result .. label .. '\t' .. value
            end
        end
        return result
    end

    local pairs_metatable = {
        __index = {
            __metrics_make_key = function(self)
                return serialize(self)
            end
        },
        -- It protects pairs from being altered with unexpected labels.
        __newindex = function(table, key, value)
            if not keys_index[key] then
                error(('Label "%s" is unexpected'):format(key), 2)
            end
            rawset(table, key, value)
        end
    }

    return {
        wrap = function(label_pairs)
            return setmetatable(label_pairs, pairs_metatable)
        end,
        serialize = serialize
    }
end

return {
    registry = registry,
    collectors = collectors,

    counter = counter,
    gauge = gauge,
    histogram = histogram,
    summary = summary,

    collect = collect,
    clear = clear,
    register_callback = register_callback,
    unregister_callback = unregister_callback,
    invoke_callbacks = invoke_callbacks,
    set_global_labels = set_global_labels,
    labels_serializer = labels_serializer
}
