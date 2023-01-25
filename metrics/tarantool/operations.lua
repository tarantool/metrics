local utils = require('metrics.utils')

local collectors_list = {}

local function update_operations_metrics()
    if not utils.box_is_configured() then
        return
    end

    local current_stat = box.stat()

    for k, v in pairs(current_stat) do
        collectors_list.stats_op_total =
            utils.set_counter('stats_op_total', 'Total amount of operations',
                v.total, {operation = k:lower()}, nil, {default = true})
    end
end

return {
    update = update_operations_metrics,
    list = collectors_list,
}
