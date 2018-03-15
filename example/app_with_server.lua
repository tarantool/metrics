#!/usr/bin/env tarantool

box.cfg{listen = 3301}
box.once('guest_security', function()
    box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)

package.path = package.path .. ";../?.lua"
local metrics_server = require('metrics.server')

-- expose add_observation for net.box
_G.add_observation = metrics_server.add_observation

-- expose function for querying metrics
_G.execute = metrics_server.execute

metrics_server.start {
    retention_tuples = 10,
}
