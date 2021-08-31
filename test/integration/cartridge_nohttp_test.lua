local fio = require('fio')
local t = require('luatest')
local g = t.group('cartridge-without-http')

local helpers = require('test.helper')

g.test_http_disabled = function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    local cluster = helpers.init_cluster()
    local server = cluster.main_server

    server.net_box:eval([[
        local cartridge = require('cartridge')
        _G.old_service = cartridge.service_get('httpd')
        cartridge.service_set('httpd', nil)
    ]])

    local ret = helpers.set_export(cluster, {
        {
            path = '/metrics',
            format = 'json',
        },
    })
    t.assert_not(ret)

    server.net_box:eval([[
        require('cartridge').service_set('httpd', _G.old_service)
    ]])

    cluster:stop()
    fio.rmtree(cluster.datadir)
end
