local fio = require('fio')
local t = require('luatest')
local g = t.group('cartridge-hotreload')

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
                {
                    path = '/metrics',
                    format = 'json'
                },
            },
        }
    })
end

g.test_cartridge_hotreload = function()
    local main_server = g.cluster:server('main')
    t.skip_if(main_server.net_box:eval([[ return pcall(require, 'cartridge.roles') == false ]]))
    t.skip_if(main_server.net_box:eval([[ return require('cartridge.roles').reload == nil ]]))

    main_server.net_box:eval([[
        box.schema.space.create('test'):create_index('pkey')
        box.schema.space.create('vinni_test', {engine='vinyl'}):create_index('pkey')
        box.space.test:put{1, 1}
        box.space.vinni_test:put{1, 1}
    ]])

    upload_config()
    local resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics')
    t.assert_str_contains(resp.body, '"test"')
    t.assert_str_contains(resp.body, '"vinni_test"')

    main_server = g.cluster:server('main')
    main_server.net_box:eval([[
        require('cartridge.roles').reload()
    ]])

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 200)

    local replica = g.cluster:server('replica')
    replica.net_box:eval([[
        require('cartridge.roles').reload()
    ]])

    replica = g.cluster:server('replica')
    resp = replica:http_request('get', '/health')
    t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics')
    t.assert_str_contains(resp.body, '"test"')
    t.assert_str_contains(resp.body, '"vinni_test"')
end
