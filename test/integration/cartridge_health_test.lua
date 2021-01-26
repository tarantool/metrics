local fio = require('fio')
local t = require('luatest')
local g = t.group()

local utils = require('test.utils')
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

local function check_cartridge_version()
    -- Health check is compatible cartridge 2.0.2 or greater
    local cartridge_version = require('cartridge.VERSION')
    t.skip_if(cartridge_version == 'unknown', 'Cartridge version is unknown, must be v2.0.2 or greater')
    t.skip_if(utils.is_version_less(cartridge_version, '2.0.2'), 'Cartridge version is must be v2.0.2 or greater')
end

g.test_cartridge_health_handler = function()
    check_cartridge_version()
    upload_config()
    local main_server = g.cluster:server('main')
    local resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_health_fail_handler = function()
    check_cartridge_version()
    upload_config()
    local main_server = g.cluster:server('main')
    main_server.net_box:eval([[
        box.info = {
                status = 'orphan',
            }
    ]])
    local resp = main_server:http_request('get', '/health')
    t.assert_equals(resp.status, 500)
end
