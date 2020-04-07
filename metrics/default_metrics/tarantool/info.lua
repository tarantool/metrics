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

    local idle = 0

    for k, v in ipairs(info.replication) do
        if v.upstream ~= nil then
            utils.set_gauge('replication_' .. k .. '_lag', 'Replication lag for instance ' .. k, v.upstream.lag)
            if v.upstream.idle > idle then
                idle = v.upstream.idle
            end
        end
    end

    if idle ~= 0 then
        local replication_timeout = box.cfg.replication_timeout
        local replication_state_normal = 0
        if idle <= replication_timeout then
            replication_state_normal = 1
        end
        utils.set_gauge('replication_state_normal', 'Is replication healthy?', replication_state_normal)
    end
end

return {
    update = update_info_metrics,
}
