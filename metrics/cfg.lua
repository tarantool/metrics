-- Based on https://github.com/tarantool/crud/blob/73bf5bf9353f9b9ee69c95bb14c610be8f2daeac/crud/cfg.lua

local checks = require('checks')

local metrics_api = require('metrics.api')
local const = require('metrics.const')
local stash = require('metrics.stash')
local metrics_tarantool = require('metrics.tarantool')

-- Split a metrics.cfg include/exclude side into two parts: built-in metric
-- groups for metrics.tarantool and custom selectors for the registry filter.
local function split_metric_groups_and_selectors(values, default_value,
                                                 empty_default,
                                                 empty_selectors)
    values = values or default_value

    if type(values) == 'string' then
        return values, values
    end

    -- Built-in metric groups are handled by metrics.tarantool, while unknown
    -- values are treated as custom selectors and passed to the registry filter.
    local default_metrics = {}
    local custom_selectors = {}
    for _, value in ipairs(values) do
        if value == const.ALL or metrics_tarantool.is_default_metric(value) then
            table.insert(default_metrics, value)
        else
            table.insert(custom_selectors, {selector = value})
        end
    end

    if next(default_metrics) == nil then
        default_metrics = empty_default
    end

    if next(custom_selectors) == nil then
        custom_selectors = empty_selectors
    end

    return default_metrics, custom_selectors
end

local function set_defaults_if_empty(cfg)
    if cfg.include == nil then
        cfg.include = const.ALL
    end

    if cfg.exclude == nil then
        cfg.exclude = {}
    end

    if cfg.labels == nil then
        cfg.labels = {}
    end

    return cfg
end

local function configure(cfg, opts)
    if opts.include == nil then
        opts.include = cfg.include
    end

    if opts.exclude == nil then
        opts.exclude = cfg.exclude
    end

    if opts.labels == nil then
        opts.labels = cfg.labels
    end


    local default_include, selector_include =
        split_metric_groups_and_selectors(opts.include, const.ALL, const.NONE,
                                          const.ALL)
    local default_exclude, selector_exclude =
        split_metric_groups_and_selectors(opts.exclude, {}, {}, {})

    metrics_tarantool.enable_v2(default_include, default_exclude)
    metrics_api.set_filter(selector_include, selector_exclude)
    metrics_api.set_global_labels(opts.labels)

    rawset(cfg, 'include', opts.include)
    rawset(cfg, 'exclude', opts.exclude)
    rawset(cfg, 'labels', opts.labels)
end

local _cfg = set_defaults_if_empty(stash.get(stash.name.cfg))
local _cfg_internal = stash.get(stash.name.cfg_internal)

if _cfg_internal.initialized then
    configure(_cfg, {})
end

local function __call(self, opts)
    checks('table', {
        include = '?string|table',
        exclude = '?table',
        labels = '?table',
    })

    opts = table.deepcopy(opts) or {}

    configure(_cfg, opts)

    _cfg_internal.initialized = true

    return self
end

local function __index(_, key)
    if _cfg_internal.initialized then
        return _cfg[key]
    else
        error('Call metrics.cfg{} first')
    end
end

local function __newindex()
    error('Use metrics.cfg{} instead')
end

return {
    -- Iterating through `metrics.cfg` with pairs is not supported yet.
    cfg = setmetatable({}, {
        __index = __index,
        __newindex = __newindex,
        __call = __call,
        __serialize = function() return _cfg end
    }),
}
