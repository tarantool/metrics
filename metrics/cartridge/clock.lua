local utils = require('metrics.utils')
local topology = require('cartridge.topology')
local confapplier = require('cartridge.confapplier')
local membership = require('membership')
local fun = require('fun')

local function update_clock_metrics()
    -- from https://github.com/tarantool/cartridge/blob/cc607f5a6508449608f3953a3f93669e8c8c4ab0/cartridge/issues.lua

    local uri_list = {}
    local topology_cfg = confapplier.get_readonly('topology')

    if topology_cfg == nil then
        return
    end
    if not topology.refine_servers_uri then
        return
    end
    local refined_uri_list = topology.refine_servers_uri(topology_cfg)
    for _, uuid, _ in fun.filter(topology.not_disabled, topology_cfg.servers) do
        table.insert(uri_list, refined_uri_list[uuid])
    end

    local min_delta = 0
    local max_delta = 0
    local members = membership.members()
    for _, server_uri in pairs(uri_list) do
        local member = members[server_uri]
        if member and member.status == 'alive' and member.clock_delta ~= nil then
            if member.clock_delta < min_delta then
                min_delta = member.clock_delta
            end

            if member.clock_delta > max_delta then
                max_delta = member.clock_delta
            end
        end
    end

    utils.set_gauge('clock_delta', 'Clock difference', min_delta * 1e-6, {delta = 'min'})
    utils.set_gauge('clock_delta', 'Clock difference', max_delta * 1e-6, {delta = 'max'})
end

return {
    update = update_clock_metrics
}
