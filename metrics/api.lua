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
else
    setmetatable(registry, Registry)
    if registry.filter == nil then
        registry:reset_filter()
    end
end
registry.callbacks = {}

rawset(_G, '__metrics_registry', registry)

--- Return a table of all registered collectors.
---@return table<string, metrics.collector>
local function collectors()
    return registry:filtered_collectors()
end

--- Register a callback that is called right before metric collection.
---@param callback function
---@param metainfo metrics.metainfo?
---@return any
local function register_callback(callback, metainfo)
    checks('function', '?table')

    return registry:register_callback(callback, metainfo)
end

--- Unregister a callback.
---@vararg any
---@return any
local function unregister_callback(...)
    return registry:unregister_callback(...)
end

--- Invoke all registered callbacks.
---@return any
local function invoke_callbacks()
    return registry:invoke_callbacks()
end

---@param collector metrics.collector
---@param result metrics.observation[]
local function get_collector_values(collector, result)
    for _, obs in ipairs(collector:collect()) do
        table.insert(result, obs)
    end
end

--- Collect observations from each collector.
---@param opts {invoke_callbacks?: boolean, default_only?: boolean}?
---@return metrics.observation[]
local function collect(opts)
    checks({invoke_callbacks = '?boolean', default_only = '?boolean'})
    opts = opts or {}

    if opts.invoke_callbacks then
        registry:invoke_callbacks()
    end

    local result = {}
    for _, collector in pairs(registry:filtered_collectors()) do
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

--- Clear all collectors and callbacks from the registry.
---@return any
local function clear()
    registry:clear()
end

--- Register a new counter.
---@param name string
---@param help string?
---@param metainfo metrics.metainfo?
---@param label_keys string[]?
---@return metrics.collector.counter
local function counter(name, help, metainfo, label_keys)
    checks('string', '?string', '?table', '?table')

    return registry:find_or_create(Counter, name, help, metainfo, label_keys)
end

--- Register a new gauge.
---@param name string
---@param help string?
---@param metainfo metrics.metainfo?
---@param label_keys string[]?
---@return metrics.collector.gauge
local function gauge(name, help, metainfo, label_keys)
    checks('string', '?string', '?table', '?table')

    return registry:find_or_create(Gauge, name, help, metainfo, label_keys)
end

--- Register a new histogram.
---@param name string
---@param help string?
---@param buckets number[]?
---@param metainfo metrics.metainfo?
---@return metrics.collector.histogram
local function histogram(name, help, buckets, metainfo)
    checks('string', '?string', '?table', '?table')
    if buckets ~= nil and not Histogram.check_buckets(buckets) then
        error('Invalid value for buckets')
    end

    return registry:find_or_create(Histogram, name, help, buckets, metainfo)
end

--- Register a new summary.
---@param name string
---@param help string?
---@param objectives table<number, number>?
---@param params {age_buckets_count?: number, max_age_time?: number}?
---@param metainfo metrics.metainfo?
---@return metrics.collector.summary
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

--- Set global labels applied to every observation.
---@param label_pairs metrics.label_pairs?
---@return any
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

--- Set a runtime filter for collectors and callbacks by metric selectors.
---@param include string|table?
---@param exclude string|table?
---@return any
local function set_filter(include, exclude)
    checks('?string|table', '?string|table')

    registry:set_filter(include, exclude)
end

---@class metrics.namespace
---@field selector string

local Namespace = {}
Namespace.__index = Namespace

---@param self table
---@param name string
---@param metainfo metrics.metainfo?
---@return metrics.metainfo
local function namespace_metainfo(self, name, metainfo)
    --- @type metrics.metainfo
    local res = table.copy(metainfo) or {}
    res.selector = res.selector or (self.selector .. '.' .. name)
    return res
end

--- Register a new counter in the namespace.
---@param name string
---@param help string?
---@param metainfo metrics.metainfo?
---@param label_keys string[]?
---@return metrics.collector.counter
function Namespace:counter(name, help, metainfo, label_keys)
    return counter(name, help, namespace_metainfo(self, name, metainfo),
                   label_keys)
end

--- Register a new gauge in the namespace.
---@param name string
---@param help string?
---@param metainfo metrics.metainfo?
---@param label_keys string[]?
---@return metrics.collector.gauge
function Namespace:gauge(name, help, metainfo, label_keys)
    return gauge(name, help, namespace_metainfo(self, name, metainfo),
                 label_keys)
end

--- Register a new histogram in the namespace.
---@param name string
---@param help string?
---@param buckets number[]?
---@param metainfo metrics.metainfo?
---@return metrics.collector.histogram
function Namespace:histogram(name, help, buckets, metainfo)
    return histogram(name, help, buckets,
                     namespace_metainfo(self, name, metainfo))
end

--- Register a new summary in the namespace.
---@param name string
---@param help string?
---@param objectives table<number, number>?
---@param params {age_buckets_count?: number, max_age_time?: number}?
---@param metainfo metrics.metainfo?
---@return metrics.collector.summary
function Namespace:summary(name, help, objectives, params, metainfo)
    return summary(name, help, objectives, params,
                   namespace_metainfo(self, name, metainfo))
end

--- Register a callback in the namespace.
---@param callback function
---@param metainfo metrics.metainfo?
---@return any
function Namespace:register_callback(callback, metainfo)
    local res = table.copy(metainfo) or {}
    res.selector = res.selector or self.selector
    return register_callback(callback, res)
end

--- Unregister a callback from the namespace.
---@param callback function
---@return any
function Namespace.unregister_callback(_, callback)
    return unregister_callback(callback)
end

--- Create a namespace object that marks collectors and callbacks with
--- selectors derived from `selector`.
---@param selector string
---@return metrics.namespace
local function namespace(selector)
    checks('string')
    if selector == '' then
        error('Metric namespace selector must not be empty')
    end

    return setmetatable({selector = selector}, Namespace)
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
    set_filter = set_filter,
    namespace = namespace,
}
