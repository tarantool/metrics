local metrics = require('metrics')

local default_metrics = {
    network = require('metrics.default_metrics.tarantool.network'),
    operations = require('metrics.default_metrics.tarantool.operations'),
    system = require('metrics.default_metrics.tarantool.system'),
    replicas = require('metrics.default_metrics.tarantool.replicas'),
    info = require('metrics.default_metrics.tarantool.info'),
    slab = require('metrics.default_metrics.tarantool.slab'),
    runtime = require('metrics.default_metrics.tarantool.runtime'),
    memory = require('metrics.default_metrics.tarantool.memory'),
    spaces = require('metrics.default_metrics.tarantool.spaces'),
    fibers = require('metrics.default_metrics.tarantool.fibers'),
    cpu = require('metrics.default_metrics.tarantool.cpu'),
    vinyl = require('metrics.tarantool.vinyl'),
    luajit = require('metrics.tarantool.luajit'),
    cartridge_issues = require('metrics.cartridge.issues'),
    clock = require('metrics.cartridge.clock'),
}

local function enable(include, exclude)
    include = include or {}
    exclude = exclude or {}

    local exclude_map = {}
    for _, name in ipairs(exclude) do
        exclude_map[name] = true
    end
    local include_map = {}
    for _, name in ipairs(include) do
        include_map[name] = true
    end

    for name, value in pairs(default_metrics) do
        if #include > 0 then
            if include_map[name] ~= nil then
                metrics.register_callback(value.update)
            else
                metrics.unregister_callback(value.update)
            end
        elseif #exclude > 0 then
            if exclude_map[name] ~= nil then
                metrics.unregister_callback(value.update)
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
