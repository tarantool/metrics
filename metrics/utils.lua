local metrics_api = require('metrics.api')

local TNT_PREFIX = 'tnt_'
local utils = {}

function utils.set_gauge(name, description, value, labels, prefix, metainfo)
    prefix = prefix or TNT_PREFIX
    local gauge = metrics_api.gauge(prefix .. name, description, metainfo)
    gauge:set(value, labels or {})
    return gauge
end

function utils.set_counter(name, description, value, labels, prefix, metainfo)
    prefix = prefix or TNT_PREFIX
    local counter = metrics_api.counter(prefix .. name, description, metainfo)
    counter:reset(labels or {})
    counter:inc(value, labels or {})
    return counter
end

function utils.box_is_configured()
    local is_configured = type(box.cfg) ~= 'function'
    if is_configured then
        utils.box_is_configured = function() return true end
    end
    return is_configured
end

function utils.delete_collectors(list)
    if list == nil then
        return
    end
    for _, collector in pairs(list) do
        metrics_api.registry:unregister(collector)
    end
    table.clear(list)
end

return utils
