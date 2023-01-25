local utils = require('metrics.utils')
local clock = require('clock')

local collectors_list = {}

local function update_system_metrics()
    if not utils.box_is_configured() then
        return
    end

    collectors_list.cfg_current_time = utils.set_gauge('cfg_current_time', 'Tarantool cfg time', clock.time() + 0ULL,
        nil, nil, {default = true})
end

return {
    update = update_system_metrics,
    list = collectors_list,
}
