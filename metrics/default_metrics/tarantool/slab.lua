local utils = require('metrics.utils')

local function update_slab_metrics()
    if not utils.box_is_configured() then
        return
    end

    local slab_info = box.slab.info()

    for k, v in pairs(slab_info) do
        if not k:match('_ratio$') then
            utils.set_gauge('slab_' .. k, 'Slab ' .. k .. ' info', v)
        else
            utils.set_gauge('slab_' .. k, 'Slab ' .. k .. ' info', tonumber(v:match('^([0-9%.]+)%%?$')))
        end
    end
end

return {
    update = update_slab_metrics
}