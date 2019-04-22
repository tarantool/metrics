local utils = require('metrics.default_metrics.tarantool.utils');

local function update_operations_metrics()
    if not utils.box_is_configured() then
        return
    end

    local current_stat = box.stat()

    for k, v in pairs(current_stat) do
        utils.set_gauge('stats_op_' .. k:lower() .. '_total', 'Total amount of ' .. k:lower() .. 's', v.total)
        utils.set_gauge('stats_op_' .. k:lower() .. '_rps', 'Total RPS ' .. k:lower() .. 's', v.rps)
    end
end

return {
    update = update_operations_metrics
}
