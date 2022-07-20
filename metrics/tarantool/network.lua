local utils = require('metrics.utils')

local collectors_list = {}

local function update_network_metrics()
    if not utils.box_is_configured() then
        return
    end

    local box_stat_net = box.stat.net()

    collectors_list.net_sent_total =
        utils.set_counter('net_sent_total', 'Totally sent in bytes', box_stat_net.SENT.total)
    collectors_list.net_sent_rps =
        utils.set_gauge('net_sent_rps', 'Sending RPS', box_stat_net.SENT.rps)
    collectors_list.net_received_total =
        utils.set_counter('net_received_total', 'Totally received in bytes', box_stat_net.RECEIVED.total)
    collectors_list.net_received_rps =
        utils.set_gauge('net_received_rps', 'Receive RPS', box_stat_net.RECEIVED.rps)

    -- https://github.com/tarantool/doc/issues/760

    -- before tnt version 2.2.0
    if box_stat_net.CONNECTIONS ~= nil and type(box_stat_net.CONNECTIONS) ~= 'number' then
        collectors_list.net_connections_rps =
            utils.set_gauge('net_connections_rps', 'Connection RPS', box_stat_net.CONNECTIONS.rps)
        collectors_list.net_connections_total =
            utils.set_counter('net_connections_total', 'Connections total amount', box_stat_net.CONNECTIONS.total)
        collectors_list.net_connections_current =
            utils.set_gauge('net_connections_current', 'Current connections amount', box_stat_net.CONNECTIONS.current)
    elseif box_stat_net.CONNECTIONS ~= nil then
        collectors_list.net_connections_current =
            utils.set_gauge('net_connections_current', 'Current connections amount', box_stat_net.CONNECTIONS)
    end

    if box_stat_net.REQUESTS ~= nil then
        collectors_list.net_requests_rps =
            utils.set_gauge('net_requests_rps', 'Requests RPS', box_stat_net.REQUESTS.rps)
        collectors_list.net_requests_total =
            utils.set_counter('net_requests_total', 'Requests total amount', box_stat_net.REQUESTS.total)
        collectors_list.net_requests_current =
            utils.set_gauge('net_requests_current', 'Pending requests', box_stat_net.REQUESTS.current)
    end

    if box_stat_net.REQUESTS_IN_PROGRESS ~= nil then
        collectors_list.net_requests_in_progress_total =
            utils.set_counter('net_requests_in_progress_total', 'Requests in progress total amount',
            box_stat_net.REQUESTS_IN_PROGRESS.total)
        collectors_list.net_requests_in_progress_current =
            utils.set_gauge('net_requests_in_progress_current',
            'Count of requests currently being processed in the tx thread', box_stat_net.REQUESTS_IN_PROGRESS.current)
    end

    if box_stat_net.REQUESTS_IN_STREAM_QUEUE ~= nil then
        collectors_list.net_requests_in_stream_total =
            utils.set_counter('net_requests_in_stream_queue_total',
            'Total count of requests, which was placed in queues of streams',
            box_stat_net.REQUESTS_IN_STREAM_QUEUE.total)
        collectors_list.net_requests_in_stream_current =
            utils.set_gauge('net_requests_in_stream_queue_current',
            'count of requests currently waiting in queues of streams', box_stat_net.REQUESTS_IN_STREAM_QUEUE.current)
    end

    if box.stat.net.thread ~= nil then
        local box_stat_net_per_thread = box.stat.net.thread()

        for index, _box_stat_net in pairs(box_stat_net_per_thread) do
            collectors_list.net_sent_total =
                utils.set_counter('net_sent_total', 'Totally sent in bytes', _box_stat_net.SENT.total, {thread = index})

            collectors_list.net_sent_rps =
                utils.set_gauge('net_sent_rps', 'Sending RPS', _box_stat_net.SENT.rps, {thread = index})

            collectors_list.net_received_total =
                utils.set_counter('net_received_total', 'Totally received in bytes', _box_stat_net.RECEIVED.total, {thread = index})

            collectors_list.net_received_rps =
                utils.set_gauge('net_received_rps', 'Receive RPS', _box_stat_net.RECEIVED.rps, {thread = index})

            if _box_stat_net.CONNECTIONS ~= nil and type(_box_stat_net.CONNECTIONS) ~= 'number' then
                collectors_list.net_connections_rps =
                    utils.set_gauge('net_connections_rps', 'Connection RPS', _box_stat_net.CONNECTIONS.rps, {thread = index})

                collectors_list.net_connections_total =
                    utils.set_counter('net_connections_total', 'Connections total amount', _box_stat_net.CONNECTIONS.total, {thread = index})

                collectors_list.net_connections_current =
                    utils.set_gauge('net_connections_current', 'Current connections amount', _box_stat_net.CONNECTIONS.current, {thread = index})

            elseif _box_stat_net.CONNECTIONS ~= nil then
                collectors_list.net_connections_current =
                    utils.set_gauge('net_connections_current', 'Current connections amount', _box_stat_net.CONNECTIONS, {thread = index})
            end

            if _box_stat_net.REQUESTS ~= nil then
                collectors_list.net_requests_rps =
                    utils.set_gauge('net_requests_rps', 'Requests RPS', _box_stat_net.REQUESTS.rps, {thread = index})

                collectors_list.net_requests_total =
                    utils.set_counter('net_requests_total', 'Requests total amount', _box_stat_net.REQUESTS.total, {thread = index})

                collectors_list.net_requests_current =
                    utils.set_gauge('net_requests_current', 'Pending requests', _box_stat_net.REQUESTS.current, {thread = index})
            end

            if _box_stat_net.REQUESTS_IN_PROGRESS ~= nil then
                collectors_list.net_requests_in_progress_total =
                    utils.set_counter('net_requests_in_progress_total', 'Requests in progress total amount',
                    _box_stat_net.REQUESTS_IN_PROGRESS.total, {thread = index})

                collectors_list.net_requests_in_progress_current =
                    utils.set_gauge('net_requests_in_progress_current', 'Count of requests currently being processed in the tx thread',
                    _box_stat_net.REQUESTS_IN_PROGRESS.current, {thread = index})
            end

            if _box_stat_net.REQUESTS_IN_STREAM_QUEUE ~= nil then
                collectors_list.net_requests_in_stream_queue_total =
                    utils.set_counter('net_requests_in_stream_queue_total', 'Total count of requests, which was placed in queues of streams',
                    _box_stat_net.REQUESTS_IN_STREAM_QUEUE.total, {thread = index})

                collectors_list.net_requests_in_stream_queue_current =
                    utils.set_gauge('net_requests_in_stream_queue_current', 'count of requests currently waiting in queues of streams',
                    _box_stat_net.REQUESTS_IN_STREAM_QUEUE.current, {thread = index})
            end
        end
    end
end


return {
    update = update_network_metrics,
    list = collectors_list,
}
