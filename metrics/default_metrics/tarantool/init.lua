local metrics = require('metrics')

local default_metrics = {
    require('metrics.default_metrics.tarantool.network'),
    require('metrics.default_metrics.tarantool.operations'),
    require('metrics.default_metrics.tarantool.system'),
    require('metrics.default_metrics.tarantool.replicas'),
    require('metrics.default_metrics.tarantool.info'),
    require('metrics.default_metrics.tarantool.slab'),
    require('metrics.default_metrics.tarantool.runtime'),
    require('metrics.default_metrics.tarantool.memory'),
    require('metrics.default_metrics.tarantool.spaces'),
    require('metrics.default_metrics.tarantool.fibers'),
}

local function enable()
    for _, metric in ipairs(default_metrics) do
        metrics.register_callback(metric.update)
    end
end

return {
    enable = enable,
}
