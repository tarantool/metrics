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
    -- local main_server = g.cluster:server('main')
    -- main_server:upload_config({
    --     metrics = {
    --         export = {
    --             {
    --                 path = '/health',
    --                 format = 'health'
    --             },
    --             {
    --                 path = '/metrics',
    --                 format = 'json'
    --             },
    --         },
    --     }
    -- })
end

local function set_export(export)
    local server = g.cluster.main_server
    return server.net_box:eval([[
        local cartridge = require('cartridge')
        local metrics = cartridge.service_get('metrics')
        local _, err = pcall(
            metrics.set_export, ...
        )
        return err
    ]], {export})
end

g.test_cartridge_hotreload = function()
    local main_server = g.cluster:server('main')
    t.skip_if(main_server.net_box:eval([[ return pcall(require, 'cartridge.roles') == false ]]))
    t.skip_if(main_server.net_box:eval([[ return require('cartridge.roles').reload == nil ]]))

    set_export({
        {
            path = '/health',
            format = 'health'
        },
        {
            path = '/metrics',
            format = 'json'
        },
    })

    main_server.net_box:eval([[
        box.schema.space.create('test'):create_index('pkey')
        box.schema.space.create('vinni_test', {engine='vinyl'}):create_index('pkey')
        box.space.test:put{1, 1}
        box.space.vinni_test:put{1, 1}
    ]])

    -- upload_config()
    local resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics')
    t.assert_str_contains(resp.body, '"test"')
    t.assert_str_contains(resp.body, '"vinni_test"')

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 200)

    main_server = g.cluster:server('main')
    local ok, err = main_server.net_box:eval([[
        return require('cartridge.roles').reload()
    ]])
    -- require'log'.error(err)
    -- assert(ok == true, tostring(err))

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/health', {raise = false})
    t.assert_equals(resp.status, 200)

    -- local replica = g.cluster:server('replica')
    -- replica.net_box:eval([[
    --     require('cartridge.roles').reload()
    -- ]])

    -- replica = g.cluster:server('replica')
    -- resp = replica:http_request('get', '/health')
    -- t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics')
    t.assert_str_contains(resp.body, '"test"')
    t.assert_str_contains(resp.body, '"vinni_test"')
end
