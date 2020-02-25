local utils = require('metrics.default_metrics.tarantool.utils');


local function update_replicas_metrics()
    if not utils.box_is_configured() then
        return
    end

    local current_box_info = box.info()

    if box.cfg.read_only then
        for k, v in ipairs(current_box_info.vclock) do
            local lsn = current_box_info.replication[k].lsn
            utils.set_gauge('replication_replica_' .. k .. '_lsn', 'lsn for replica ' .. k, lsn - v)
        end
    else
        for k, v in ipairs(current_box_info.replication) do
            if v.downstream ~= nil and v.downstream.vclock ~= nil then
                local lsn = v.downstream.vclock[current_box_info.id]
                if lsn ~= nil and current_box_info.lsn ~= nil then
                    utils.set_gauge(
                            'replication_master_' .. k .. '_lsn',
                            'lsn for master ' .. k,
                            current_box_info.lsn - lsn
                    )
                end
            end

            if v.upstream ~= nil then
                utils.set_gauge('replication_lag_' .. k,
                    'The time difference between the master and the replica ' .. k,
                    v.upstream.lag)
            end
        end
    end
end

return {
    update = update_replicas_metrics
}
