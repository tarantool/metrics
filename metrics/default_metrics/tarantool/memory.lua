local utils = require('metrics.utils')

local function update_memory_metrics()
    if not utils.box_is_configured() then
        return
    end

    if box.info.memory ~= nil then
        local i = box.info.memory()
        for k, v in pairs(i) do
            utils.set_gauge('info_memory_' .. k, 'Memory' .. k, v)
        end
    end
end

return {
    update = update_memory_metrics
}