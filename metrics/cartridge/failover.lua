local is_cartridge = pcall(require, 'cartridge')

if not is_cartridge then
    return {
        update = function() end,
        list = {},
    }
end

local utils = require('metrics.utils')
local collectors_list = {}
local vars = require('cartridge.vars').new('cartridge.failover')

local function update()
    local trigger_cnt = vars.failover_trigger_cnt
    if trigger_cnt ~= nil then
        collectors_list.trigger_cnt =
            utils.set_gauge(
                'cartridge_failover_trigger',
                'Count of Cartridge Failover triggers',
                trigger_cnt
            )
    end
end

return {
    update = update,
    list = collectors_list,
}
