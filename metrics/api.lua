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
}
