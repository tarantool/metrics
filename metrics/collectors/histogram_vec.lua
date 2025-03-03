local Shared = require('metrics.collectors.shared')
local new_histogram_vec = require('metrics_rs').new_histogram_vec

local HistogramVec = Shared:new_class('histogram', {})

---@param label_names string[]
function HistogramVec:new(name, help, label_names, buckets, metainfo)
    metainfo = table.copy(metainfo) or {}
    local obj = Shared.new(self, name, help, metainfo)

    obj._label_names = label_names or {}
    obj.inner = new_histogram_vec({
        name = name,
        help = help,
        buckets = buckets, -- can be nil
    }, obj._label_names)

    obj._observe = obj.inner.observe
    obj._collect = obj.inner.collect
    obj._collect_str = obj.inner.collect_str

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
    -- self._observe(self.inner, value, label_values)
    self.inner:observe(value, label_values)
end

function HistogramVec:remove(label_pairs)
    assert(label_pairs, 'label pairs is a required parameter')
    local label_values = to_values(label_pairs, self._label_names)
    self.inner:remove(label_values)
end

function HistogramVec:collect_str()
    local global_labels = self:append_global_labels({})
    return self.inner:collect_str(global_labels)
end

-- Slow collect
function HistogramVec:collect()
    local global_labels = self:append_global_labels({})
    return self.inner:collect(global_labels)
end

return HistogramVec
