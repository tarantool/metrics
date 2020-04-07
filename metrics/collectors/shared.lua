local fiber = require('fiber')

local Shared = {}

function Shared.new(name, help, kind)
    if not name then
        error("Name should be set for %s", kind)
    end

    local obj = {}
    obj.name = name
    obj.help = help or ""
    obj.observations = {}
    obj.label_pairs = {}
    obj.kind = kind

    return obj
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

local function append_global_labels(label_pairs)
    if next(global_metrics_registry.label_pairs) == nil then
        return label_pairs
    end

    local extended_label_pairs = table.copy(label_pairs)

    for k, v in pairs(global_metrics_registry.label_pairs) do
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
            label_pairs = append_global_labels(self.label_pairs[key]),
            value = observation,
            timestamp = fiber.time64(),
        }
        table.insert(result, obs)
    end
    return result
end

return Shared
