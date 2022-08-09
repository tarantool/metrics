local metrics = require('metrics')

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
    luajit              = require('metrics.tarantool.luajit'),
    cartridge_issues    = require('metrics.cartridge.issues'),
    cartridge_failover  = require('metrics.cartridge.failover'),
    clock               = require('metrics.tarantool.clock'),
    event_loop          = require('metrics.tarantool.event_loop'),
}

local function delete_collectors(list)
    if list == nil then
        return
    end
    for _, collector in pairs(list) do
        metrics.registry:unregister(collector)
    end
    table.clear(list)
end

local function enable(include, exclude)
    include = include or {}
    exclude = exclude or {}
    if next(include) ~= nil and next(exclude) ~= nil then
        error('Only one of "exclude" or "include" should present')
    end

    local exclude_map = {}
    for _, name in ipairs(exclude) do
        exclude_map[name] = true
    end
    local include_map = {}
    for _, name in ipairs(include) do
        include_map[name] = true
    end

    for name, value in pairs(default_metrics) do
        if next(include) ~= nil then
            if include_map[name] ~= nil then
                metrics.register_callback(value.update)
            else
                metrics.unregister_callback(value.update)
                delete_collectors(value.list)
            end
        elseif next(exclude) ~= nil then
            if exclude_map[name] ~= nil then
                metrics.unregister_callback(value.update)
                delete_collectors(value.list)
            else
                metrics.register_callback(value.update)
            end
        else
            metrics.register_callback(value.update)
        end
    end
end

return {
    enable = enable,
}
