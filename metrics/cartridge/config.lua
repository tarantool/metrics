local utils = require('metrics.utils')
local collectors_list = {}

local function update()
    local is_cartridge = pcall(require, 'cartridge')
    if not is_cartridge then
        return
    end

    local confapplier = require('cartridge.confapplier')
    local clusterwide_config = confapplier.get_active_config()
    if clusterwide_config ~= nil then
        collectors_list.config_checksum =
            utils.set_gauge(
                'cartridge_config_checksum',
                'Cartridge configuration checksum on the instance',
                clusterwide_config:get_checksum(),
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
