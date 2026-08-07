local metrics_api = require('metrics.api')

local TNT_PREFIX = 'tnt_'
local utils = {}

---@param name string
---@param description string
---@param value number?
---@param labels metrics.label_pairs?
---@param prefix string?
---@param metainfo metrics.metainfo?
---@return metrics.collector.gauge
function utils.set_gauge(name, description, value, labels, prefix, metainfo)
    prefix = prefix or TNT_PREFIX
    local gauge = metrics_api.gauge(prefix .. name, description, metainfo)
    gauge:set(value, labels or {})
    return gauge
end

---@param name string
---@param description string
---@param value number?
---@param labels metrics.label_pairs?
---@param prefix string?
---@param metainfo metrics.metainfo?
---@return metrics.collector.counter
function utils.set_counter(name, description, value, labels, prefix, metainfo)
    prefix = prefix or TNT_PREFIX
    local counter = metrics_api.counter(prefix .. name, description, metainfo)
    counter:reset(labels or {})
    counter:inc(value, labels or {})
    return counter
end

---@return boolean
function utils.box_is_configured()
    local is_configured = type(box.cfg) ~= 'function'
    if is_configured then
        utils.box_is_configured = function() return true end
    end
    return is_configured
end

---@param list table<string, metrics.collector>?
---@return any
function utils.delete_collectors(list)
    if list == nil then
        return
    end
    for _, collector in pairs(list) do
        metrics_api.registry:unregister(collector)
    end
    table.clear(list)
end

local function get_tarantool_version()
    local version_parts = rawget(_G, '_TARANTOOL'):split('-', 3)

    local major_minor_patch_parts = version_parts[1]:split('.', 2)
    local major = tonumber(major_minor_patch_parts[1])
    local minor = tonumber(major_minor_patch_parts[2])
    local patch = tonumber(major_minor_patch_parts[3])

    return major, minor, patch
end

---@return boolean
function utils.is_tarantool3()
    local major = get_tarantool_version()
    return major == 3
end

return utils
