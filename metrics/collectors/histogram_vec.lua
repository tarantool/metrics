local Shared = require('metrics.collectors.shared')
local collectors = require('metrics_rs').collectors
local fiber = require 'fiber'

local HistogramVec = Shared:new_class('histogram', {})

---@param label_names string[]
function HistogramVec:new(name, help, label_names, buckets, metainfo)
    metainfo = table.copy(metainfo) or {}
    local obj = Shared.new(self, name, help, metainfo)

    obj._label_names = label_names or {}
    obj.histogram_vec = collectors.new_histogram_vec({
        name = name,
        help = help,
        buckets = buckets, -- can be nil
    }, obj._label_names)

    return obj
end

local function to_values(label_pairs, keys)
    local n = #keys
    local values = table.new(n, 0)
    for i, name in ipairs(keys) do
        values[i] = label_pairs[name]
    end
    return values
end

function HistogramVec:observe(value, label_pairs)
    local label_values
    if type(label_pairs) == 'table' then
        label_values = to_values(label_pairs, self._label_names)
    end
    self.histogram_vec:observe(value, label_values)
end

function HistogramVec:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    local label_values = to_values(label_pairs, self._label_names)
    self.histogram_vec:remove(label_values)
end

function HistogramVec:collect()
    local global_labels = self:append_global_labels({})
    return self.histogram_vec:collect(fiber.time(), global_labels)
end

return HistogramVec
