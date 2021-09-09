local utils = require('metrics.utils')

local collectors_list = {}

local read_only_status = {
    [true] = 1,
    [false] = 0,
}

local function update_info_metrics()
    if not utils.box_is_configured() then
        return
    end

    local info = box.info()

    collectors_list.info_lsn = utils.set_gauge('info_lsn', 'Tarantool lsn', info.lsn)
    collectors_list.info_uptime = utils.set_gauge('info_uptime', 'Tarantool uptime', info.uptime)

    for k, v in ipairs(info.vclock) do
        collectors_list.info_vclock = utils.set_gauge('info_vclock', 'VClock', v, {id = k})
    end

    for k, v in ipairs(info.replication) do
        if v.upstream ~= nil then
            local metric_name = 'replication_' .. k .. '_lag'
            collectors_list[metric_name] =
                utils.set_gauge(metric_name, 'Replication lag for instance ' .. k, v.upstream.lag)
        end
    end

    collectors_list.read_only = utils.set_gauge('read_only', 'Is instance read only', read_only_status[info.ro])
end

return {
    update = update_info_metrics,
    list = collectors_list,
}
