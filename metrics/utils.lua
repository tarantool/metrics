local metrics = require('metrics')

local TNT_PREFIX = 'tnt_'

local function prefix_name(name)
    return TNT_PREFIX .. name
end

local function set_gauge(name, description, value, labels)
    local gauge = metrics.gauge(prefix_name(name), description)
    gauge:set(value, labels or {})
    return gauge
end

local function box_is_configured()
    return type(box.cfg) ~= 'function'
end

return {
    set_gauge = set_gauge,
    box_is_configured = box_is_configured,
    prefix_name = prefix_name,
}
