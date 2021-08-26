local metrics = require('metrics')

local TNT_PREFIX = 'tnt_'

local function set_gauge(name, description, value, labels, prefix)
    prefix = prefix or TNT_PREFIX
    local gauge = metrics.gauge(prefix .. name, description)
    gauge:set(value, labels or {})
    return gauge
end

local function set_counter(name, description, value, labels, prefix)
    prefix = prefix or TNT_PREFIX
    local counter = metrics.counter(prefix .. name, description)
    counter:reset(labels or {})
    counter:inc(value, labels or {})
    return counter
end

local function box_is_configured()
    return type(box.cfg) ~= 'function'
end

return {
    set_gauge = set_gauge,
    set_counter = set_counter,
    box_is_configured = box_is_configured,
}
