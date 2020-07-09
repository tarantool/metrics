local utils = require('metrics.utils')

local function update_runtime_metrics()
    local runtime_info = box.runtime.info()

    for k, v in pairs(runtime_info) do
        if k ~= 'maxalloc' then
            utils.set_gauge('runtime_' .. k, 'Runtime ' .. k, v)
        end
    end
end

return {
    update = update_runtime_metrics,
}