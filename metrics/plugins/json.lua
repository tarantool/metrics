local metrics = require('metrics')
local string_utils = require('metrics.string_utils')
local json = require('json')
local json_exporter = {}

local function finite(value)
    if type(value) == "string" then
        value = tonumber(value)
        if value == nil then return nil end
    elseif type(value) == "cdata" then -- support number64
        return value
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

json_exporter.internal = {}  -- For test purposes.
function json_exporter.internal.collect_and_serialize_v1()
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

function json_exporter.format_output(output)
    local result = {}
    for _, coll_obs in pairs(output) do
        for group_name, obs_group in pairs(coll_obs.observations) do
            local metric_name = string_utils.build_name(coll_obs.name, group_name)
            for _, obs in pairs(obs_group) do
                table.insert(result, {
                    metric_name = metric_name,
                    label_pairs = format_label_pairs(obs.label_pairs),
                    timestamp = coll_obs.timestamp,
                    value = format_value(obs.value),
                })
            end
        end
    end

    return json.encode(result)
end

function json_exporter.internal.collect_and_serialize_v2()
    local output = metrics.collect{invoke_callbacks = true, extended_format = true}
    return json_exporter.format_output(output)
end

json_exporter.export = json_exporter.internal.collect_and_serialize_v2

return json_exporter
