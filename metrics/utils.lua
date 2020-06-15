local metrics = require('metrics')

local gauges_storage = {}

local TNT_PREFIX = 'tnt_'

local function prefix_name(name)
    return TNT_PREFIX .. name
end

local function set_gauge(name, description, value, labels)
    if (gauges_storage[name] == nil) then
        gauges_storage[name] = metrics.gauge(prefix_name(name), description)
    end

    gauges_storage[name]:set(value, labels or {})
end


local function box_is_configured()
    return type(box.cfg) ~= 'function'
end

return {
    set_gauge = set_gauge,
    box_is_configured = box_is_configured,
    prefix_name = prefix_name,
}