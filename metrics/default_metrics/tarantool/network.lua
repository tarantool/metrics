local utils = require('metrics.utils')


local function update_network_metrics()
    if not utils.box_is_configured() then
        return
    end

    local box_stat_net = box.stat.net()

    utils.set_gauge('net_sent_total', 'Totally sent in bytes', box_stat_net.SENT.total)
    utils.set_gauge('net_sent_rps', 'Sending RPS', box_stat_net.SENT.rps)
    utils.set_gauge('net_received_total', 'Totally received in bytes', box_stat_net.RECEIVED.total)
    utils.set_gauge('net_received_rps', 'Receive RPS', box_stat_net.RECEIVED.rps)

    -- https://github.com/tarantool/doc/issues/760

    -- before tnt version 2.2.0
    if box_stat_net.CONNECTIONS ~= nil and type(box_stat_net.CONNECTIONS) ~= 'number' then
        utils.set_gauge('net_connections_rps', 'Connection RPS', box_stat_net.CONNECTIONS.rps)
        utils.set_gauge('net_connections_total', 'Connections total amount', box_stat_net.CONNECTIONS.total)
        utils.set_gauge('net_connections_current', 'Current connections amount', box_stat_net.CONNECTIONS.current)
    elseif box_stat_net.CONNECTIONS ~= nil then
        utils.set_gauge('net_connections_current', 'Current connections amount', box_stat_net.CONNECTIONS)
    end

    if box_stat_net.REQUESTS ~= nil then
        utils.set_gauge('net_requests_rps', 'Requests RPS', box_stat_net.REQUESTS.rps)
        utils.set_gauge('net_requests_total', 'Requests total amount', box_stat_net.REQUESTS.total)
        utils.set_gauge('net_requests_current', 'Pending requests', box_stat_net.REQUESTS.current)
    end
end


return {
    update = update_network_metrics,
}
