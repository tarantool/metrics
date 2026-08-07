-- vim: ts=4:sw=4:sts=4:expandtab

local log = require('log')

local api = require('metrics.api')
local const = require('metrics.const')
local cfg = require('metrics.cfg')
local http_middleware = require('metrics.http_middleware')
local tarantool = require('metrics.tarantool')

local VERSION = require('metrics.version')

---@class metrics
---@field registry metrics.registry
---@field counter fun(name: string, help?: string, metainfo?: metrics.metainfo, label_keys?: string[]): metrics.collector.counter
---@field gauge fun(name: string, help?: string, metainfo?: metrics.metainfo, label_keys?: string[]): metrics.collector.gauge
---@field histogram fun(name: string, help?: string, buckets?: number[], metainfo?: metrics.metainfo): metrics.collector.histogram
---@field summary fun(name: string, help?: string, objectives?: table<number, number>,
---    params?: {age_buckets_count?: number, max_age_time?: number}, metainfo?: metrics.metainfo): metrics.collector.summary
---@field INF number
---@field NAN number
---@field clear fun(): any
---@field collectors fun(): table<string, metrics.collector>
---@field namespace fun(selector: string): metrics.namespace
---@field register_callback fun(callback: function, metainfo?: metrics.metainfo): any
---@field unregister_callback fun(...: any): any
---@field invoke_callbacks fun(): any
---@field set_global_labels fun(label_pairs?: metrics.label_pairs): any
---@field set_filter fun(include?: string|table, exclude?: string|table): any
---@field enable_default_metrics fun(include?: string|table, exclude?: table): any
---@field cfg fun(opts?: {include?: string|table, exclude?: table, labels?: metrics.label_pairs}): table
---@field http_middleware table
---@field collect fun(opts?: {invoke_callbacks?: boolean, default_only?: boolean}): metrics.observation[]
---@field _VERSION string

return setmetatable({
    registry = api.registry,

    counter = api.counter,
    gauge = api.gauge,
    histogram = api.histogram,
    summary = api.summary,

    INF = const.INF,
    NAN = const.NAN,

    clear = api.clear,
    collectors = api.collectors,
    namespace = api.namespace,
    register_callback = api.register_callback,
    unregister_callback = api.unregister_callback,
    invoke_callbacks = api.invoke_callbacks,
    set_global_labels = api.set_global_labels,
    set_filter = api.set_filter,
    enable_default_metrics = tarantool.enable,
    cfg = cfg.cfg,
    http_middleware = http_middleware,
    collect = api.collect,
    _VERSION = VERSION,
}, {
    __index = function(_, key)
        if key == 'VERSION' then
            log.warn("require('metrics').VERSION is deprecated, " ..
                     "use require('metrics')._VERSION instead.")
            return VERSION
        end

        return nil
    end
})
