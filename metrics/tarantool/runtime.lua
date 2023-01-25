local utils = require('metrics.utils')

local collectors_list = {}

local function update_runtime_metrics()
    local runtime_info = box.runtime.info()

    for k, v in pairs(runtime_info) do
        if k ~= 'maxalloc' then
            local metric_name = 'runtime_' .. k
            collectors_list[metric_name] = utils.set_gauge(metric_name, 'Runtime ' .. k, v,
                nil, nil, {default = true})
        end
    end
end

return {
    update = update_runtime_metrics,
    list = collectors_list,
}
