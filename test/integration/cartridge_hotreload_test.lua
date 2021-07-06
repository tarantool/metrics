local fio = require('fio')
local t = require('luatest')
local g = t.group()
local utils = require('test.utils')

local helpers = require('test.helper')

g.before_each(function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    local cartridge_version = require('cartridge.VERSION')
    t.skip_if(cartridge_version == 'unknown')
    t.skip_if(utils.is_version_less(cartridge_version, '2.3.0'))
    g.cluster = helpers.Cluster:new({
        datadir = fio.tempdir(),
        server_command = helpers.entrypoint('srv_with_hotreload'),
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
end)

g.after_each(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end)

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
                    path = '/new-metrics',
                    format = 'json'
                },
            },
        }
    })
end

local function set_export()
    local export = {
        {
            path = '/health',
            format = 'health'
        },
        {
            path = '/metrics',
            format = 'json'
        },
    }
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

local function reload_roles()
    local main_server = g.cluster:server('main')
    main_server.net_box:eval([[
        require('cartridge.roles').reload()
    ]])
end

g.test_cartridge_hotreload_set_export = function()
    local main_server = g.cluster:server('main')
    set_export()

    local resp = main_server:http_request('get', '/metrics')
    t.assert_equals(resp.status, 200)

    reload_roles()

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_hotreload_config = function()
    local main_server = g.cluster:server('main')

    upload_config()
    local resp = main_server:http_request('get', '/new-metrics')
    t.assert_equals(resp.status, 200)

    reload_roles()

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_hotreload_set_export_and_config = function()
    local main_server = g.cluster:server('main')

    set_export()

    upload_config()
    local resp = main_server:http_request('get', '/new-metrics')
    t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics')
    t.assert_equals(resp.status, 200)

    reload_roles()

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics')
    t.assert_equals(resp.status, 200)
end
