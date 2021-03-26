local utils = require('metrics.utils');
local fun = require('fun')

local gather_global_issues = true

local function update_info_metrics()
    local status, cartridge_issues = pcall(require, 'cartridge.issues')

    if not gather_global_issues and status ~= true then
        return
    end

    local issues = cartridge_issues.list_on_cluster()

    local levels = { 'warning', 'critical' }

    for _, level in ipairs(levels) do
        local len = fun.iter(issues):filter(function(x) return x.level == level end):length()
        utils.set_gauge(cartridge_issues, 'Tarantool Cartridge issues', len, {level = level})
    end

end

local function disable_global_issues()
    gather_global_issues = false
end

return {
    update = update_info_metrics,
    disable_global_issues = disable_global_issues,
}
