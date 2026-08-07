local clock = require('clock')
local fiber = require('fiber')
local log = require('log')

---@alias metrics.label_pairs table<string, string|number>
---@alias metrics.metainfo table
---@alias metrics.observation {metric_name: string, label_pairs: metrics.label_pairs, value: number, timestamp: integer}

---@class metrics.collector
---@field name string
---@field help string
---@field observations table<string, number>
---@field label_pairs table<string, metrics.label_pairs>
---@field label_keys string[]|nil
---@field metainfo metrics.metainfo
---@field registry metrics.registry|nil

local Shared = {}

-- Create collector class with the list of instance methods copied from
-- this class (like an inheritance but with limited list of methods).
---@param kind string
---@param method_names string[]?
---@return metrics.collector
function Shared:new_class(kind, method_names)
    method_names = method_names or {}
    -- essential methods
    table.insert(method_names, 'new')
    table.insert(method_names, 'set_registry')
    table.insert(method_names, 'make_key')
    table.insert(method_names, 'append_global_labels')
    table.insert(method_names, 'collect')
    table.insert(method_names, 'remove')
    local methods = {}
    for _, name in pairs(method_names) do
        methods[name] = self[name]
    end
    local class = {kind = kind}
    class.__index = class
    return setmetatable(class, {__index = methods})
end

---@generic T
---@param self T
---@param name string
---@param help string?
---@param metainfo metrics.metainfo?
---@param label_keys string[]?
---@return T
function Shared.new(self, name, help, metainfo, label_keys)
    metainfo = table.copy(metainfo) or {}

    if not name then
        error("Name should be set for %s")
    end
    return setmetatable({
        name = name,
        help = help or "",
        observations = {},
        label_pairs = {},
        label_keys = label_keys,
        metainfo = metainfo,
    }, self)
end

---@param registry metrics.registry
function Shared:set_registry(registry)
    self.registry = registry
end

---@param label_pairs metrics.label_pairs|nil
---@param label_keys string[]?
---@return string
function Shared.make_key(label_pairs, label_keys)
    if label_keys == nil then
        if type(label_pairs) ~= 'table' then
            return ""
        end

        local parts = {}
        for k, v in pairs(label_pairs) do
            table.insert(parts, k .. '\t' .. v)
        end
        table.sort(parts)

        return table.concat(parts, '\t')
    end

    if type(label_pairs) ~= 'table' then
        error("Invalid label_pairs: expected a table when label_keys is provided")
    end

    local label_count = 0
    for _ in pairs(label_pairs) do
        label_count = label_count + 1
    end

    if #label_keys ~= label_count then
        error(("Label keys count (%d) should match " ..
            "the number of label pairs (%d)"):format(#label_keys, label_count))
    end

    local parts = table.new(#label_keys, 0)
    for i, label_key in ipairs(label_keys) do
        local label_value = label_pairs[label_key]
        if label_value == nil then
            error(string.format("Label key '%s' is missing", label_key))
        end
        parts[i] = label_value
    end

    return table.concat(parts, '\t')
end

--- Remove the observation for `label_pairs`.
---@param label_pairs metrics.label_pairs?
function Shared:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    local key = self.make_key(label_pairs, self.label_keys)
    self.observations[key] = nil
    self.label_pairs[key] = nil
end

--- Set the observation for `label_pairs` to `num`.
---@param num number?
---@param label_pairs metrics.label_pairs?
function Shared:set(num, label_pairs)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector set value should be a number")
    end
    num = num or 0
    local key = self.make_key(label_pairs, self.label_keys)
    self.observations[key] = num
    self.label_pairs[key] = label_pairs or {}
end

--- Increment the observation for `label_pairs`.
---@param num number?
---@param label_pairs metrics.label_pairs?
function Shared:inc(num, label_pairs)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector increment should be a number")
    end
    num = num or 1
    local key = self.make_key(label_pairs, self.label_keys)
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value + num
    self.label_pairs[key] = label_pairs or {}
end

--- Decrement the observation for `label_pairs`.
---@param num number?
---@param label_pairs metrics.label_pairs?
function Shared:dec(num, label_pairs)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector decrement should be a number")
    end
    num = num or 1
    local key = self.make_key(label_pairs, self.label_keys)
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
---
---@param label_pairs metrics.label_pairs|fun(ok: boolean, result: any, ...: any): metrics.label_pairs|nil
---      either table with labels or function to generate labels.
---      If function is given its called with the results of pcall.
---@param fn function function for pcall to instrument
---@vararg any args for function fn
---@return any value from fn
function Shared:observe_latency(label_pairs, fn, ...)
    return observe_latency_tail(self, label_pairs, clock.monotonic(), pcall(fn, ...))
end

---@param label_pairs metrics.label_pairs|nil
---@return metrics.label_pairs
function Shared:append_global_labels(label_pairs)
    local global_labels = self.registry and self.registry.label_pairs
    if global_labels == nil or next(global_labels) == nil then
        return label_pairs or {}
    end

    local extended_label_pairs = table.copy(label_pairs)

    for k, v in pairs(global_labels) do
        if extended_label_pairs[k] == nil then
            extended_label_pairs[k] = v
        end
    end

    return extended_label_pairs
end

--- Return an array of observation objects for the collector.
---@return metrics.observation[]
function Shared:collect()
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

return Shared
