local metrics_api = require('metrics.api')
local utils = require('metrics.utils')
local const = require('metrics.const')

local default_metrics = {
    network             = require('metrics.tarantool.network'),
    operations          = require('metrics.tarantool.operations'),
    system              = require('metrics.tarantool.system'),
    replicas            = require('metrics.tarantool.replicas'),
    info                = require('metrics.tarantool.info'),
    slab                = require('metrics.tarantool.slab'),
    runtime             = require('metrics.tarantool.runtime'),
    memory              = require('metrics.tarantool.memory'),
    spaces              = require('metrics.tarantool.spaces'),
    fibers              = require('metrics.tarantool.fibers'),
    cpu                 = require('metrics.tarantool.cpu'),
    vinyl               = require('metrics.tarantool.vinyl'),
    memtx               = require('metrics.tarantool.memtx'),
    luajit              = require('metrics.tarantool.luajit'),
    cartridge_issues    = require('metrics.cartridge.issues'),
    cartridge_failover  = require('metrics.cartridge.failover'),
    clock               = require('metrics.tarantool.clock'),
    event_loop          = require('metrics.tarantool.event_loop'),
}

local function enable_impl(include, exclude)
    include = include or const.ALL
    exclude = exclude or {}

    local include_map = {}

    if include == const.ALL then
        for name, _ in pairs(default_metrics) do
            include_map[name] = true
        end
    elseif type(include) == 'table' then
        for _, name in pairs(include) do
            include_map[name] = true
        end
    elseif include == const.NONE then
        include_map = {}
    else
        error('Unexpected value provided: include must be "all", {...} or "none"')
    end

    for _, name in pairs(exclude) do
        include_map[name] = false
    end

    for name, value in pairs(default_metrics) do
        if include_map[name] then
            metrics_api.register_callback(value.update)
        else
            metrics_api.unregister_callback(value.update)
            utils.delete_collectors(value.list)
        end
    end
end

local function is_empty_table(v)
    return (type(v) == 'table') and (next(v) == nil)
end

local function enable(include, exclude)
    -- Compatibility with v1.
    if is_empty_table(include) then
        include = const.ALL
    end

    return enable_impl(include, exclude)
end

return {
    enable = enable,
}
