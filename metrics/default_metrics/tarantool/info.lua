local utils = require('metrics.utils');

local function update_info_metrics()
    if not utils.box_is_configured() then
        return
    end

    local info = box.info()

    utils.set_gauge('info_lsn', 'Tarantool lsn', info.lsn)
    utils.set_gauge('info_uptime', 'Tarantool uptime', info.uptime)

    for k, v in ipairs(info.vclock) do
        utils.set_gauge('info_vclock', 'VClock', v, {id = k})
    end

    for k, v in ipairs(info.replication) do
        if v.upstream ~= nil then
            utils.set_gauge('replication_' .. k .. '_lag', 'Replication lag for instance ' .. k, v.upstream.lag)
        end
    end
end

return {
    update = update_info_metrics,
}
