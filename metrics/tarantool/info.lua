local utils = require('metrics.utils')

local collectors_list = {}

local read_only_status = {
    [true] = 1,
    [false] = 0,
}

local election_states = {
    follower = 0,
    candidate = 1,
    leader = 2,
}

local function update_info_metrics()
    if not utils.box_is_configured() then
        return
    end

    local info = box.info()

    collectors_list.info_lsn = utils.set_gauge('info_lsn', 'Tarantool lsn', info.lsn)
    collectors_list.info_uptime = utils.set_gauge('info_uptime', 'Tarantool uptime', info.uptime)

    for k, v in pairs(info.vclock) do
        collectors_list.info_vclock = utils.set_gauge('info_vclock', 'VClock', v, {id = k})
    end

    for k, v in pairs(info.replication) do
        if v.upstream ~= nil then
            collectors_list.replication_lag =
                utils.set_gauge('replication_lag', 'Replication lag', v.upstream.lag, {stream = 'upstream', id = k})
            collectors_list.replication_status =
                utils.set_gauge('replication_status', 'Replication status', v.upstream.status == 'follow' and 1 or 0,
                {stream = 'upstream', id = k})
        end
        if v.downstream ~= nil then
            collectors_list.replication_lag =
                utils.set_gauge('replication_lag', 'Replication lag', v.downstream.lag, {stream = 'downstream', id = k})
            collectors_list.replication_status =
                utils.set_gauge('replication_status', 'Replication status', v.downstream.status == 'follow' and 1 or 0,
                {stream = 'downstream', id = k})
        end
    end

    collectors_list.read_only = utils.set_gauge('read_only', 'Is instance read only', read_only_status[info.ro])

    if info.synchro ~= nil then
        collectors_list.synchro_queue_owner =
            utils.set_gauge('synchro_queue_owner', 'Synchro queue owner',
                info.synchro.queue.owner)

        collectors_list.synchro_queue_term =
            utils.set_gauge('synchro_queue_term', 'Synchro queue term',
                info.synchro.queue.term)

        collectors_list.synchro_queue_len =
            utils.set_gauge('synchro_queue_len', 'Amount of transactions are collecting confirmations now',
                info.synchro.queue)

        collectors_list.synchro_queue_busy =
            utils.set_gauge('synchro_queue_busy', 'Is synchro queue busy',
                info.synchro.busy == true and 1 or 0)
    end

    if info.election ~= nil then
        collectors_list.election_state =
            utils.set_gauge('election_state', 'Election state of the node',
                election_states[info.election.state])

        collectors_list.election_vote =
            utils.set_gauge('election_vote', 'ID of a node the current node votes for',
                info.election.vote)

        collectors_list.election_leader =
            utils.set_gauge('election_leader', 'Leader node ID in the current term',
                info.election.leader)

        collectors_list.election_term =
            utils.set_gauge('election_term', 'Current election term',
                info.election.term)
    end
end

return {
    update = update_info_metrics,
    list = collectors_list,
}
