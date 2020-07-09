local utils = require('metrics.utils')


local function update_replicas_metrics()
    if not utils.box_is_configured() then
        return
    end

    local current_box_info = box.info()

    if box.cfg.read_only then
        for k, v in ipairs(current_box_info.vclock) do
            local replication_info = current_box_info.replication[k]
            if replication_info then
                local lsn = replication_info.lsn
                utils.set_gauge('replication_replica_' .. k .. '_lsn', 'lsn for replica ' .. k, lsn - v)
            end
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
        end
    end
end

return {
    update = update_replicas_metrics
}
