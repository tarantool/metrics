local clock = require('clock')
local fiber = require('fiber')
local log = require('log')

local string_utils = require('metrics.string_utils')

local Shared = {}

-- Create collector class with the list of instance methods copied from
-- this class (like an inheritance but with limited list of methods).
function Shared:new_class(kind, method_names)
    method_names = method_names or {}
    -- essential methods
    table.insert(method_names, 'new')
    table.insert(method_names, 'set_registry')
    table.insert(method_names, 'make_key')
    table.insert(method_names, 'append_global_labels')
    table.insert(method_names, 'collect')
    table.insert(method_names, '_collect_v1_implementation')
    table.insert(method_names, '_collect_v2_implementation')
    table.insert(method_names, '_collect_v2_observations')
    table.insert(method_names, 'remove')
    local methods = {}
    for _, name in pairs(method_names) do
        methods[name] = self[name]
    end

    string_utils.check_symbols(kind)
    local class = {kind = kind}
    class.__index = class
    return setmetatable(class, {__index = methods})
end

function Shared:new(name, help, metainfo)
    metainfo = table.copy(metainfo) or {}

    if not name then
        error("Name should be set for %s")
    end
    string_utils.check_symbols(name)

    return setmetatable({
        name = name,
        name_prefix = name:gsub('_total$', ''):gsub('_current$', ''),
        help = help or "",
        observations = {},
        label_pairs = {},
        metainfo = metainfo,
    }, self)
end

function Shared:set_registry(registry)
    self.registry = registry
end

function Shared.make_key(label_pairs)
    if type(label_pairs) ~= 'table' then
        return ""
    end
    local parts = {}
    for k, v in pairs(label_pairs) do
        string_utils.check_symbols(k)
        string_utils.check_symbols(v)
        table.insert(parts, k .. '\t' .. v)
    end
    table.sort(parts)
    return table.concat(parts, '\t')
end

function Shared:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    local key = self.make_key(label_pairs)
    self.observations[key] = nil
    self.label_pairs[key] = nil
end

function Shared:set(num, label_pairs)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector set value should be a number")
    end
    num = num or 0
    local key = self.make_key(label_pairs)
    self.observations[key] = num
    self.label_pairs[key] = label_pairs or {}
end

function Shared:inc(num, label_pairs)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector increment should be a number")
    end
    num = num or 1
    local key = self.make_key(label_pairs)
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value + num
    self.label_pairs[key] = label_pairs or {}
end

function Shared:dec(num, label_pairs)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector decrement should be a number")
    end
    num = num or 1
    local key = self.make_key(label_pairs)
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value - num
    self.label_pairs[key] = label_pairs or {}
end

local function log_observe_latency_error(err)
    log.error(debug.traceback('Saving metrics failed: ' .. tostring(err)))
end

local function observe_latency_tail(collector, label_pairs, start_time, ok, result, ...)
    local latency = clock.monotonic() - start_time
    if type(label_pairs) == 'function' then
        label_pairs = label_pairs(ok, result, ...)
    end
    xpcall(
        collector.observe,
        log_observe_latency_error,
        collector, latency, label_pairs
    )
    if not ok then
        error(result)
    end
    return result, ...
end

--- Measure latency of function call
--
-- @param label_pairs either table with labels or function to generate labels.
--      If function is given its called with the results of pcall.
-- @param fn function for pcall to instrument
-- ... - args for function fn
-- @return value from fn
function Shared:observe_latency(label_pairs, fn, ...)
    return observe_latency_tail(self, label_pairs, clock.monotonic(), pcall(fn, ...))
end

function Shared:append_global_labels(label_pairs)
    local global_labels = self.registry and self.registry.label_pairs
    if global_labels == nil or next(global_labels) == nil then
        return label_pairs
    end

    local extended_label_pairs = table.copy(label_pairs)

    for k, v in pairs(global_labels) do
        if extended_label_pairs[k] == nil then
            extended_label_pairs[k] = v
        end
    end

    return extended_label_pairs
end

function Shared:_collect_v1_implementation()
    if next(self.observations) == nil then
        return {}
    end
    local result = {}
    for key, observation in pairs(self.observations) do
        local obs = {
            metric_name = self.name,
            label_pairs = self:append_global_labels(self.label_pairs[key]),
            value = observation,
            timestamp = fiber.time64(),
        }
        table.insert(result, obs)
    end
    return result
end

function Shared:_collect_v2_observations()
    local observations = {}

    for key, value in pairs(self.observations) do
        local obs = {
            label_pairs = self:append_global_labels(self.label_pairs[key]),
            value = value,
        }
        observations[key] = obs
    end
    return observations
end

function Shared:_collect_v2_implementation()
    return {
        name = self.name,
        name_prefix = self.name_prefix,
        kind = self.kind,
        help = self.help,
        metainfo = self.metainfo,
        timestamp = fiber.time64(),
        observations = {
            [''] = self:_collect_v2_observations(),
        }
    }
end

function Shared:collect(opts)
    opts = opts or {}

    if opts.extended_format then
        return self:_collect_v2_implementation()
    else
        return self:_collect_v1_implementation()
    end
end

return Shared
