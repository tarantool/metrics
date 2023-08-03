local log = require("log")

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

local all_metrics_map = {}
for name, _ in pairs(default_metrics) do
    all_metrics_map[name] = true
end

local function check_metrics_name(name, raise_if_unknown)
    if default_metrics[name] == nil then
        if raise_if_unknown then
            error(string.format("Unknown metrics %q provided", name))
        else
            log.warn("Unknown metrics %q provided, this will raise an error in the future", name)
        end
    end
end

local function enable_impl(include, exclude, raise_if_unknown)
    include = include or const.ALL
    exclude = exclude or {}

    local include_map = {}

    if include == const.ALL then
        include_map = table.deepcopy(all_metrics_map)
    elseif type(include) == 'table' then
        for _, name in pairs(include) do
            if name == const.ALL then -- metasection "all"
                include_map = table.deepcopy(all_metrics_map)
            else
                check_metrics_name(name, raise_if_unknown)
                include_map[name] = true
            end
        end
    elseif include == const.NONE then
        include_map = {}
    else
        error('Unexpected value provided: include must be "all", {...} or "none"')
    end

    for _, name in pairs(exclude) do
        if name == const.ALL then -- metasection "all"
            include_map = {}
        else
            check_metrics_name(name, raise_if_unknown)
            include_map[name] = false
        end
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
        log.warn('Providing {} in enable_default_metrics include is treated ' ..
                 'as a default value now (i.e. include all), ' ..
                 'but it will change in the future. Use "all" instead')
        include = const.ALL
    end

    return enable_impl(include, exclude, false)
end

local function enable_v2(include, exclude)
    return enable_impl(include, exclude, true)
end

return {
    enable = enable,
    enable_v2 = enable_v2,
}
