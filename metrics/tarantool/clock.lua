local utils = require('metrics.utils')

local collectors_list = {}

-- from https://github.com/tarantool/cartridge/blob/cc607f5a6508449608f3953a3f93669e8c8c4ab0/cartridge/issues.lua#L375
local function update_clock_metrics()
    local ok, membership = pcall(require, 'membership')
    if not ok then
        return
    end

    local min_delta = 0
    local max_delta = 0

    for _, member in membership.pairs() do
        if member and member.status == 'alive' and member.clock_delta ~= nil then
            if member.clock_delta < min_delta then
                min_delta = member.clock_delta
            end

            if member.clock_delta > max_delta then
                max_delta = member.clock_delta
            end
        end
    end

    collectors_list.clock_delta = utils.set_gauge('clock_delta', 'Clock difference',
        min_delta * 1e-6, {delta = 'min'}, nil, {default = true})
    collectors_list.clock_delta = utils.set_gauge('clock_delta', 'Clock difference',
        max_delta * 1e-6, {delta = 'max'}, nil, {default = true})
end

return {
    update = update_clock_metrics,
    list = collectors_list,
}
