local utils = require('metrics.default_metrics.tarantool.utils');
local clock = require('clock')

local function update_system_metrics()
    if not utils.box_is_configured() then
        return
    end

    utils.set_gauge('cfg_listen', 'Tarantool port', box.cfg.listen)
    utils.set_gauge('cfg_current_time', 'Tarantool cfg time', clock.time() + 0ULL)
end

return {
    update = update_system_metrics,
}