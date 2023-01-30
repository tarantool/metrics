-- vim: ts=4:sw=4:sts=4:expandtab

local api = require('metrics.api')
local const = require('metrics.const')
local cfg = require('metrics.cfg')
local http_middleware = require('metrics.http_middleware')
local tarantool = require('metrics.tarantool')

local VERSION = '0.16.0-scm'

return {
    registry = api.registry,

    counter = api.counter,
    gauge = api.gauge,
    histogram = api.histogram,
    summary = api.summary,

    INF = const.INF,
    NAN = const.NAN,

    clear = api.clear,
    collectors = api.collectors,
    register_callback = api.register_callback,
    unregister_callback = api.unregister_callback,
    invoke_callbacks = api.invoke_callbacks,
    set_global_labels = api.set_global_labels,
    enable_default_metrics = tarantool.enable,
    cfg = cfg.cfg,
    http_middleware = http_middleware,
    collect = api.collect,
    VERSION = VERSION,
    _VERSION = VERSION,
}
