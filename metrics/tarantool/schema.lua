local utils = require('metrics.utils')
-- luacheck: globals box

local collectors_list = {}

local metric_name = 'schema_needs_upgrade'

local needs_upgrade_status = {
    [true] = 1,
    [false] = 0,
}

local function update_schema_metrics()
    if not utils.box_is_configured() then
        return
    end

    local ok, needs_upgrade = pcall(box.schema.needs_upgrade)
    if not ok then
        ok, needs_upgrade = pcall(box.internal.schema_needs_upgrade)
    end

    if ok then
        collectors_list[metric_name] = utils.set_gauge(metric_name, 'Schema needs upgrade',
            needs_upgrade_status[needs_upgrade], nil, nil, {default = true})
    end
end

return {
    update = update_schema_metrics,
    list = collectors_list,
}
