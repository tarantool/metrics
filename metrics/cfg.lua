-- Based on https://github.com/tarantool/crud/blob/73bf5bf9353f9b9ee69c95bb14c610be8f2daeac/crud/cfg.lua

local checks = require('checks')

local metrics_api = require('metrics.api')
local const = require('metrics.const')
local stash = require('metrics.stash')
local metrics_tarantool = require('metrics.tarantool')

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


    metrics_tarantool.enable_v2(opts.include, opts.exclude)
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
