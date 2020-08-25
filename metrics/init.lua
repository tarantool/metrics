-- vim: ts=4:sw=4:sts=4:expandtab

local checks = require('checks')

local Registry = require('metrics.registry')

local Counter = require('metrics.collectors.counter')
local Gauge = require('metrics.collectors.gauge')
local Histogram = require('metrics.collectors.histogram')
local Summary = require('metrics.collectors.summary')

local registry = Registry.new()

local function collectors()
    return registry.collectors
end

local function register_callback(...)
    return registry:register_callback(...)
end

local function invoke_callbacks()
    return registry:invoke_callbacks()
end

local function collect()
    return registry:collect()
end

local function clear()
    registry:clear()
end

local function counter(name, help)
    checks('string', '?string')

    return registry:find_or_create(Counter, name, help)
end

local function gauge(name, help)
    checks('string', '?string')

    return registry:find_or_create(Gauge, name, help)
end

local function histogram(name, help, buckets)
    checks('string', '?string', '?table')
    if buckets ~= nil and not Histogram.check_buckets(buckets) then
        error('Invalid value for buckets')
    end

    return registry:find_or_create(Histogram, name, help, buckets)
end

local function summary(name, help, objectives)
    checks('string', '?string', '?table')
    if objectives ~= nil and not Summary.check_quantiles(objectives) then
        error('Invalid value for objectives')
    end

    return registry:find_or_create(Summary, name, help, objectives)
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

    counter = counter,
    gauge = gauge,
    histogram = histogram,
    summary = summary,

    INF = math.huge,
    NAN = math.huge * 0,

    clear = clear,
    collectors = collectors,
    register_callback = register_callback,
    invoke_callbacks = invoke_callbacks,
    set_global_labels = set_global_labels,
    enable_default_metrics = function()
        return require('metrics.default_metrics.tarantool').enable()
    end,
    http_middleware = require('metrics.http_middleware'),
    collect = collect,
}
