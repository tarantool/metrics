local utils = require('metrics.utils')

local collectors_list = {}

local function update_slab_metrics()
    if not utils.box_is_configured() then
        return
    end

    local slab_info = box.slab.info()

    for k, v in pairs(slab_info) do
        local metric_name = 'slab_' .. k
        if not k:match('_ratio$') then
            collectors_list[metric_name] = utils.set_gauge(metric_name, 'Slab ' .. k .. ' info', v)
        else
            collectors_list[metric_name] =
                utils.set_gauge(metric_name, 'Slab ' .. k .. ' info', tonumber(v:match('^([0-9%.]+)%%?$')))
        end
    end
end

return {
    update = update_slab_metrics,
    list = collectors_list,
}
