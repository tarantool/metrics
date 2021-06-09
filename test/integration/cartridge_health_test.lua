local fio = require('fio')
local t = require('luatest')
local g = t.group()

local helpers = require('test.helper')

g.before_each(function()
    helpers.init_cluster(t, g)
end)

g.after_each(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end)

g.test_cartridge_health_handler = function()
    helpers.check_cartridge_version('2.0.2')
    helpers.upload_config(g.cluster)
    local main_server = g.cluster:server('main')
    local resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_health_fail_handler = function()
    helpers.check_cartridge_version('2.0.2')
    helpers.upload_config(g.cluster)
    local main_server = g.cluster:server('main')
    main_server.net_box:eval([[
        box.info = {
                status = 'orphan',
            }
    ]])
    local resp = main_server:http_request('get', '/health', {raise = false})
    t.assert_equals(resp.status, 500)
end
