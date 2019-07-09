-- vim: ts=4:sw=4:sts=4:expandtab

require('checks')

local net_box = require('net.box')
local fiber = require('fiber')

local details = require('metrics.details')

local function collectors()
    return global_metrics_registry.collectors
end

local function register_callback(...)
    return global_metrics_registry:register_callback(...)
end

local function invoke_callbacks()
    return global_metrics_registry:invoke_callbacks()
end

local function collect()
    return global_metrics_registry:collect()
end

local function counter(name, help)
    checks('string', '?string')

    return details.Counter.new(name, help)
end

local function gauge(name, help)
    checks('string', '?string')

    return details.Gauge.new(name, help)
end

function checkers.buckets(buckets)
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

local function histogram(name, help, buckets)
    checks('string', '?string', '?buckets')

    return details.Histogram.new(name, help, buckets)
end

local function clear()
    global_metrics_registry.collectors = {}
    global_metrics_registry.callbacks = {}
end

return {
    counter = counter,
    gauge = gauge,
    histogram = histogram,

    INF = details.INF,
    NAN = details.NAN,

    clear = clear,
    collectors = collectors,
    register_callback = register_callback,
    invoke_callbacks = invoke_callbacks,
    enable_default_metrics = function()
        return require('metrics.default_metrics.tarantool').enable()
    end,
    collect = collect,
}
