local metrics = require('metrics')
local json = require('json')
local json_exporter = {}

local function escape(str)
    return str
        :gsub("\\", "\\\\")
        :gsub("\n", "\\n")
        :gsub('"', '\\"')
end

local function finite(value)  
    if type(value) == "string" then
        value = tonumber(value)
        if value == nil then return nil end
    elseif type(value) ~= "number" then
        return nil
    end
    return value > -metrics.INF and value < metrics.INF
end

local function serialize_value(value)
    if not finite(value) then
        return tostring(value)
    else
        return value
    end
end

local function serialize_label_pairs(label_pairs)
    if next(label_pairs) == nil then
        return ''
    end

    local parts = {}
    for name, value in pairs(label_pairs) do
        local str = string.format(
            '%s="%s"',
            escape(tostring(name)), tostring(value))
        table.insert(parts, str)
    end

    local serialized = table.concat(parts, ',')
    return string.format('{%s}', serialized)
end

function json_exporter.collect()
    metrics.invoke_callbacks()
    local stat = {}

    for _, c in pairs(metrics.collectors()) do
        for _, obs in ipairs(c:collect()) do
            local serialized_name = string.format(
                '%s%s',
                escape(obs.metric_name),
                serialize_label_pairs(obs.label_pairs))

            local serialized_value = finite(obs.value) and obs.value or tostring(obs.value)
            stat[serialized_name] = {
                value = serialized_value,
                timestamp = obs.timestamp
            }
        end
    end
    return json.encode(stat)
end

return json_exporter
