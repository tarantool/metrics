local fio = require('fio')
local t = require('luatest')
local g = t.group()

local helpers = require('test.helper')

g.before_each( function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    g.cluster = helpers.Cluster:new({
        datadir = fio.tempdir(),
        server_command = helpers.entrypoint('srv_basic'),
        replicasets = {
            {
                uuid = helpers.uuid('a'),
                roles = {},
                servers = {
                    { instance_uuid = helpers.uuid('a', 1), alias = 'main' },
                    { instance_uuid = helpers.uuid('b', 1), alias = 'replica' },
                },
            },
        },
    })
    g.cluster:start()
end )

g.after_each( function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end )

local function upload_config()
    local main_server = g.cluster:server('main')
    main_server:upload_config({
        metrics = {
            export = {
                {
                    path = '/health',
                    format = 'health'
                },
            },
        }
    })
end

g.test_cartridge_health_handler = function()
    upload_config()
    local main_server = g.cluster:server('main')
    local resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 200)
end
