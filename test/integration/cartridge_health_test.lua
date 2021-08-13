local fio = require('fio')
local t = require('luatest')
local g = t.group()

local helpers = require('test.helper')

g.before_all(function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    g.cluster = helpers.init_cluster()
end)

g.after_all(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end)

g.test_cartridge_health_handler = function()
    helpers.skip_cartridge_version_less('2.0.2')
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server('main')
    local resp = main_server:http_request('get', '/health', {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_health_fail_handler = function()
    helpers.skip_cartridge_version_less('2.0.2')
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server('main')
    main_server.net_box:eval([[
        _G.old_info = box.info
        box.info = {
            status = 'orphan',
        }
    ]])
    local resp = main_server:http_request('get', '/health', {raise = false})
    t.assert_equals(resp.status, 500)
    main_server.net_box:eval([[
        box.info = _G.old_info
    ]])
end
