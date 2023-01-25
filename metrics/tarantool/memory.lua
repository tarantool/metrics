local utils = require('metrics.utils')

local collectors_list = {}

local function update_memory_metrics()
    if not utils.box_is_configured() then
        return
    end

    if box.info.memory ~= nil then
        local i = box.info.memory()
        for k, v in pairs(i) do
            local metric_name = 'info_memory_' .. k
            collectors_list[metric_name] = utils.set_gauge(metric_name, 'Memory ' .. k, v,
                nil, nil, {default = true})
        end
    end
end

return {
    update = update_memory_metrics,
    list = collectors_list,
}
