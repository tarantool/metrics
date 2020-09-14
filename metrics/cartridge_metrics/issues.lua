local utils = require('metrics.utils');

local function update_info_metrics()
    local status, cartridge_issues = pcall(require, 'cartridge.issues')

    if status ~= true then
        return
    end

    local issues = cartridge_issues.list_on_cluster()

    utils.set_gauge('cartridge_issues', 'Tarantool Cartridge issues', #issues)
end

return {
    update = update_info_metrics,
}
