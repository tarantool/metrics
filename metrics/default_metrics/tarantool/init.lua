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
}

local function enable(include, exclude)
    local exclude_map = {}
    for _, name in ipairs(exclude or {}) do
        exclude_map[name] = true
    end
    if include then
        for _, name in ipairs(include) do
            metrics.register_callback(default_metrics[name].update)
        end
    else
        for name, metric in pairs(default_metrics) do
            if not exclude_map[name] then
                metrics.register_callback(metric.update)
            end
        end
    end
end

return {
    enable = enable,
}
