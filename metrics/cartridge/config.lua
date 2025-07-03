local utils = require('metrics.utils')
local collectors_list = {}
local vars = nil

local function update()
    if vars == nil then
        local is_cartridge = pcall(require, 'cartridge')
        if not is_cartridge then
            return
        end

        vars = require('cartridge.vars').new('cartridge.twophase')
    end

    local config_applied = vars.config_applied
    if config_applied ~= nil then
        collectors_list.config_applied =
            utils.set_gauge(
                'cartridge_config_applied',
                'Whether the Cartridge configuration was successfully applied',
                config_applied and 1 or 0,
                nil,
                nil,
                {default = true}
            )
    end
end

return {
    update = update,
    list = collectors_list,
}
