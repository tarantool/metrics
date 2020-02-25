local utils = require('metrics.default_metrics.tarantool.utils');

local function update_info_metrics()
    if not utils.box_is_configured() then
        return
    end

    local info = box.info()

    utils.set_gauge('info_pid', 'Tarantool pid', info.pid)
    utils.set_gauge('info_lsn', 'Tarantool lsn', info.lsn)
    utils.set_gauge('info_uptime', 'Tarantool uptime', info.uptime)
    utils.set_gauge('info_lsn', 'Tarantool lsn', info.lsn)
    utils.set_gauge('info_uptime', 'Tarantool uptime', info.uptime)

    for k, v in ipairs(info.vclock) do
        utils.set_gauge('info_vclock_' .. k, 'VClock for ' .. k, v)
    end

    for _, replica in ipairs(info.replication) do
        if replica.upstream ~= nil then
            utils.set_gauge('replication_lag', 'Replication lag for instance',
                replica.upstream.lag, {uuid = replica.uuid})
        end
    end
end

return {
    update = update_info_metrics,
}
