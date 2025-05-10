local Shared = require('metrics.collectors.shared')
local HistogramVec = Shared:new_class('histogram', {})
local rust = require('metrics.rs')

---@param label_names string[]
function HistogramVec:new(name, help, label_names, buckets, metainfo)
    metainfo = table.copy(metainfo) or {}
    local obj = Shared.new(self, name, help, metainfo)

    obj._label_names = label_names or {}
    obj.inner = rust.new_histogram_vec({
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
    if value ~= nil then
        value = tonumber(value)
        if type(value) ~= 'number' then
            error("Histogram observation should be a number")
        end
    end

    local label_values
    if type(label_pairs) == 'table' then
        label_values = to_values(label_pairs, self._label_names)
    end
    self.inner:observe(value, label_values)
end

function HistogramVec:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    local label_values = to_values(label_pairs, self._label_names)
    self.inner:remove(label_values)
end

-- Fast collect
function HistogramVec:collect_str()
    return self.inner:collect_str()
end

-- Slow collect
function HistogramVec:collect()
    return self.inner:collect()
end

function HistogramVec:unregister()
    if self.registry then
        self.registry:unregister(self)
    end
    self.inner:unregister()
    self.inner = nil
end

return HistogramVec
