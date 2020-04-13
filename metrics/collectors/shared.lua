local fiber = require('fiber')

local Shared = {}

-- Create collector class with the list of instance methods copied from
-- this class (like an inheritance but with limited list of methods).
function Shared:new_class(kind, method_names)
    method_names = method_names or {}
    -- essential methods
    table.insert(method_names, 'new')
    table.insert(method_names, 'set_registry')
    table.insert(method_names, 'collect')
    local methods = {}
    for _, name in pairs(method_names) do
        methods[name] = self[name]
    end
    local class = {kind = kind}
    class.__index = class
    return setmetatable(class, {__index = methods})
end

function Shared:new(name, help)
    if not name then
        error("Name should be set for %s")
    end
    return setmetatable({
        name = name,
        help = help or "",
        observations = {},
        label_pairs = {},
    }, self)
end

function Shared:set_registry(registry)
    self.registry = registry
end

local function make_key(label_pairs)
    local key = ''
    for k, v in pairs(label_pairs) do
        key = key .. k .. '\t' .. v .. '\t'
    end
    return key
end

function Shared:set(num, label_pairs)
    num = num or 0
    label_pairs = label_pairs or {}
    local key = make_key(label_pairs)
    self.observations[key] = num
    self.label_pairs[key] = label_pairs
end

function Shared:inc(num, label_pairs)
    num = num or 1
    label_pairs = label_pairs or {}
    local key = make_key(label_pairs)
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value + num
    self.label_pairs[key] = label_pairs
end

function Shared:dec(num, label_pairs)
    num = num or 1
    label_pairs = label_pairs or {}
    local key = make_key(label_pairs)
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value - num
    self.label_pairs[key] = label_pairs
end

local function append_global_labels(registry, label_pairs)
    if registry == nil or next(registry.label_pairs) == nil then
        return label_pairs
    end

    local extended_label_pairs = table.copy(label_pairs)

    for k, v in pairs(registry.label_pairs) do
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
            label_pairs = append_global_labels(self.registry, self.label_pairs[key]),
            value = observation,
            timestamp = fiber.time64(),
        }
        table.insert(result, obs)
    end
    return result
end

return Shared
