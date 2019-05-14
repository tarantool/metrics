local metrics = require('metrics')

local plain_metrics = {}

local function escape(str)
    return str
        :gsub("\\", "\\\\")
        :gsub("\n", "\\n")
        :gsub('"', '\\"')
end

local function serialize_name(name)
    return escape(name)
end

local function get_value(value)
    if value == metrics.INF then
        return '+Inf'
    elseif value == -metrics.INF then
        return '-Inf'
    elseif value ~= value then
        return 'Nan'
    else
        return value
    end
end

function plain_metrics.collect()
    metrics.invoke_callbacks()
    
    local stat = {}
    for _, c in pairs(metrics.collectors()) do
        for _, obs in ipairs(c:collect()) do
            stat[serialize_name(obs.metric_name)] = serialize_value(obs.value)
        end
    end
    return stat   
end

return plain_metrics
