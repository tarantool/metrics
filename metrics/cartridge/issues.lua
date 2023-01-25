local utils = require('metrics.utils')
local fun = require('fun')

local collectors_list = {}

local function update()
    local list_on_instance = rawget(_G, '__cartridge_issues_list_on_instance')

    if not list_on_instance then
        return
    end

    local ok, issues = pcall(list_on_instance)

    if not ok then
        return
    end

    local levels = { 'warning', 'critical' }

    for _, level in ipairs(levels) do
        local len = fun.iter(issues):filter(function(x) return x.level == level end):length()
        collectors_list.cartridge_issues =
            utils.set_gauge('cartridge_issues', 'Tarantool Cartridge issues',
                len, {level = level}, nil, {default = true})
    end

    local global_issues_cnt = rawget(_G, '__cartridge_issues_cnt')
    if global_issues_cnt ~= nil then
        collectors_list.global_issues =
            utils.set_gauge('cartridge_cluster_issues', 'Tarantool Cartridge cluster issues',
                global_issues_cnt, nil, nil, {default = true})
    end
end

return {
    update = update,
    list = collectors_list,
}
