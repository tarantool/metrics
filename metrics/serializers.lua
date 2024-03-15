--- Default slow algorithm, polluted with sorting.
--- It is used when nothing is known about `label_pairs`.
local function default_labels_serializer(label_pairs)
    local parts = {}
    for k, v in pairs(label_pairs) do
        table.insert(parts, k .. '\t' .. v)
    end
    table.sort(parts)
    return table.concat(parts, '\t')
end


--- Prepares a serializer for label pairs with given keys.
---
--- `make_key`, which is used during every metric-related operation, is not very efficient itself.
--- To mitigate it, one could add his own serialization implementation.
--- It is done via passing `__metrics_serialize` callback to the label pairs table.
---
--- This function gives you ready-to-use serializer, so you don't have to create one yourself.
---
--- BEWARE! If keys of the `label_pairs` somehow change between serialization turns, it would raise error mostlikely.
--- We cover internal cases already, for example, "le" key is always added for the histograms.
---
--- @class LabelsSerializer
--- @field wrap function(label_pairs: table): table Wraps given `label_pairs` with an efficient serialization.
--- @field serialize function(label_pairs: table): string Serialize given `label_pairs` into the key.
--- Exposed so you can write your own serializers on top of it.
---
--- @param labels_keys string[] Label keys for the further use.
--- @return LabelsSerializer
local function basic_labels_serializer(labels_keys)
    -- we always add keys that are needed for metrics' internals.
    local __labels_keys = { "le" }
    -- used to protect label_pairs from altering with unexpected keys.
    local keys_index = { le = true }

    -- keep only unique labels
    for _, key in ipairs(labels_keys) do
        if not keys_index[key] then
            table.insert(__labels_keys, key)
            keys_index[key] = true
        end
    end
    table.sort(__labels_keys)

    local function serialize(label_pairs)
        local result = ""
        for _, label in ipairs(__labels_keys) do
            local value = label_pairs[label]
            if value ~= nil then
                if result ~= "" then
                    result = result .. '\t'
                end
                result = result .. label .. '\t' .. value
            end
        end
        return result
    end

    local pairs_metatable = {
        __index = {
            __metrics_serialize = function(self)
                return serialize(self)
            end
        },
        -- It protects pairs from being altered with unexpected labels.
        __newindex = function(table, key, value)
            if not keys_index[key] then
                error(('Label "%s" is unexpected'):format(key), 2)
            end
            rawset(table, key, value)
        end
    }

    return {
        wrap = function(label_pairs)
            return setmetatable(label_pairs, pairs_metatable)
        end,
        serialize = serialize
    }
end

return {
    default_labels_serializer = default_labels_serializer,
    basic_labels_serializer = basic_labels_serializer
}
