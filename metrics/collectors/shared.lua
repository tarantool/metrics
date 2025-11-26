local clock = require('clock')
local fiber = require('fiber')
local log = require('log')

local Shared = {Prepared = {}}

function Shared.Prepared:new_class(method_names)
    local methods = {}
    for _, name in ipairs(method_names or {}) do
        methods[name] = Shared.Prepared[name]
    end
    local class = {}
    class.__index = class
    return setmetatable(class, {__index = methods})
end

function Shared.Prepared:new(collector, label_pairs)
    return setmetatable({
        collector = collector,
        label_pairs = label_pairs,
        -- `make_key` is a pretty heavy method since it works with strings intensively
        -- The idea is to cache the key and re-use it for all the "prepared" statements
        key = collector:make_key(label_pairs),
    }, self)
end

function Shared.Prepared:remove()
    assert(self.label_pairs, 'label pairs is a required parameter')
    self.collector.observations[self.key] = nil
    self.collector.label_pairs[self.key] = nil
end

function Shared.Prepared:set(num)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector set value should be a number")
    end
    num = num or 0
    self.collector.observations[self.key] = num
    self.collector.label_pairs[self.key] = self.label_pairs or {}
end

function Shared.Prepared:inc(num)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector increment should be a number")
    end
    num = num or 1
    local old_value = self.collector.observations[self.key] or 0
    self.collector.observations[self.key] = old_value + num
    self.collector.label_pairs[self.key] = self.label_pairs or {}
end

function Shared.Prepared:dec(num)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Collector decrement should be a number")
    end
    num = num or 1
    local old_value = self.collector.observations[self.key] or 0
    self.collector.observations[self.key] = old_value - num
    self.collector.label_pairs[self.key] = self.label_pairs or {}
end

function Shared.Prepared:observe()
    error('Not implemented in shared class, override me')
end

function Shared.Prepared:reset()
    error('Not implemented in shared class, override me')
end

-- Create collector class with the list of instance methods copied from
-- this class (like an inheritance but with limited list of methods).
function Shared:new_class(kind, method_names)
    method_names = method_names or {}
    -- essential methods
    table.insert(method_names, 'new')
    table.insert(method_names, 'set_registry')
    table.insert(method_names, 'make_key')
    table.insert(method_names, 'prepare')
    table.insert(method_names, 'append_global_labels')
    table.insert(method_names, 'collect')
    table.insert(method_names, 'remove')
    local methods = {}
    for _, name in pairs(method_names) do
        methods[name] = self[name]
    end
    local class = {
        kind = kind,
        Prepared = Shared.Prepared:new_class(method_names),
    }
    class.__index = class
    return setmetatable(class, {__index = methods})
end

function Shared:new(name, help, metainfo, label_keys)
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

function Shared:set_registry(registry)
    self.registry = registry
end

function Shared:make_key(label_pairs)
    if (self.label_keys == nil) and (type(label_pairs) ~= 'table') then
        return ""
    end

    if self.label_keys ~= nil then
        if type(label_pairs) ~= 'table' then
            error("Invalid label_pairs: expected a table when label_keys is provided")
        end

        local label_count = 0
        for _ in pairs(label_pairs) do
            label_count = label_count + 1
        end

        if #self.label_keys ~= label_count then
            error(("Label keys count (%d) should match " ..
                "the number of label pairs (%d)"):format(#self.label_keys, label_count))
        end

        local parts = table.new(#self.label_keys, 0)
        for i, label_key in ipairs(self.label_keys) do
            local label_value = label_pairs[label_key]
            if label_value == nil then
                error(string.format("Label key '%s' is missing", label_key))
            end
            parts[i] = label_value
        end

        return table.concat(parts, '\t')
    end

    local parts = {}
    for k, v in pairs(label_pairs) do
        table.insert(parts, k .. '\t' .. v)
    end
    table.sort(parts)

    return table.concat(parts, '\t')
end

function Shared:prepare(label_pairs)
    return self.Prepared:new(self, label_pairs)
end

function Shared:remove(label_pairs)
    self:prepare(label_pairs):remove()
end

function Shared:set(num, label_pairs)
    self:prepare(label_pairs):set(num)
end

function Shared:inc(num, label_pairs)
    self:prepare(label_pairs):inc(num)
end

function Shared:dec(num, label_pairs)
    self:prepare(label_pairs):dec(num)
end

function Shared:observe(num, label_pairs)
    self:prepare(label_pairs):observe(num)
end

function Shared:reset(label_pairs)
    self:prepare(label_pairs):reset()
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
