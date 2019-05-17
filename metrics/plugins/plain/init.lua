local metrics = require('metrics')

local plain_metrics = {}

function plain_metrics.collect()
    metrics.invoke_callbacks()
    
    local stat = {}
    for _, c in pairs(metrics.collectors()) do
        for _, obs in ipairs(c:collect()) do
            stat[obs.metric_name] = {
                value = tostring(obs.value),
                label_pairs = obs.label_pairs,
                timestamp = obs.timestamp
            }
        end
    end
    return stat 
end

return plain_metrics
