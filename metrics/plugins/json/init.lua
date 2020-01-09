local metrics = require('metrics')
local json = require('json')
local json_exporter = {}

local function finite(value)
    if type(value) == "string" then
        value = tonumber(value)
        if value == nil then return nil end
    elseif type(value) ~= "number" then
        return nil
    end
    return value > -metrics.INF and value < metrics.INF
end

local function format_value(value)
    return finite(value) and value or tostring(value)
end

local function format_label_pairs(label_pairs)
    local part = {}
    if next(label_pairs) ~= nil then
        for name, value in pairs(label_pairs) do
            part[tostring(name)] = format_value(value)
        end
    end
    return part
end

local function format_observation(obs)
    local part = {
        metric_name = obs.metric_name,
        value = format_value(obs.value),
        label_pairs = format_label_pairs(obs.label_pairs),
        timestamp = obs.timestamp
    }
    return part
end

function json_exporter.export()
    metrics.invoke_callbacks()
    local stat = {}

    for _, c in pairs(metrics.collectors()) do
        for _, obs in ipairs(c:collect()) do
            local part = format_observation(obs)
            table.insert(stat, part)
        end
    end
    return json.encode(stat)
end

return json_exporter
