local fio = require('fio')
local t = require('luatest')
local g = t.group('cartridge-without-http')

local helpers = require('test.helper')

local function set_export(cluster, export)
    local server = cluster.main_server
    return server.net_box:eval([[
        local cartridge = require('cartridge')
        local metrics = cartridge.service_get('metrics')
        local _, err = pcall(
            metrics.set_export, ...
        )
        return err
    ]], {export})
end

g.test_http_disabled = function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    local cluster = helpers.init_cluster()
    local server = cluster.main_server

    server.net_box:eval([[
        local cartridge = require('cartridge')
        _G.old_service = cartridge.service_get('httpd')
        cartridge.service_set('httpd', nil)
    ]])

    local ret = set_export(cluster, {
        {
            path = '/metrics',
            format = 'json',
        },
    })
    t.assert_not(ret)

    cluster:stop()
    fio.rmtree(cluster.datadir)
end
