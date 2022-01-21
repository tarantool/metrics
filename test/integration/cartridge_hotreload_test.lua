local fio = require('fio')
local t = require('luatest')
local g = t.group()

local helpers = require('test.helper')
local utils = require('test.utils')

g.before_all(function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    helpers.skip_cartridge_version_less('2.3.0')
    g.cluster = helpers.init_cluster({TARANTOOL_ROLES_RELOAD_ALLOWED = 'true'})
end)

g.after_all(function()
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
    t.assert(main_server.net_box:eval([[
        return require('cartridge.roles').reload()
    ]]))
end

g.test_cartridge_hotreload_set_export = function()
    local main_server = g.cluster:server('main')
    local resp = main_server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    set_export()

    resp = main_server:http_request('get', '/metrics', {raise = false})
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
    local resp = main_server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    reload_roles()

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    resp = main_server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_hotreload_set_labels = function()
    local main_server = g.cluster:server('main')
    main_server.net_box:eval([[
        local metrics = require('cartridge.roles.metrics')
        metrics.set_default_labels(...)
    ]], {{
        system = 'some-system',
        app_name = 'myapp',
    }})
    reload_roles()

    local resp = main_server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    for _, obs in pairs(resp.json) do
        t.assert_equals(obs.label_pairs.system, 'some-system')
        t.assert_equals(obs.label_pairs.app_name, 'myapp')
        t.assert_equals(obs.label_pairs.alias, 'main')
    end
end

g.test_cartridge_hotreload_labels_from_config = function()
    local main_server = g.cluster:server('main')
    main_server:upload_config({
        metrics = {
            export = {
                {
                    path = '/metrics',
                    format = 'json'
                },
            },
            ['global-labels'] = {
                system = 'some-system',
                app_name = 'myapp',
            }
        }
    })

    reload_roles()

    local resp = main_server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    for _, obs in pairs(resp.json) do
        t.assert_equals(obs.label_pairs.system, 'some-system')
        t.assert_equals(obs.label_pairs.app_name, 'myapp')
        t.assert_equals(obs.label_pairs.alias, 'main')
    end
end

g.test_cartridge_hotreload_labels_from_config_and_set_labels = function()
    local main_server = g.cluster:server('main')
    main_server:upload_config({
        metrics = {
            export = {
                {
                    path = '/metrics',
                    format = 'json'
                },
            },
            ['global-labels'] = {
                system = 'some-system',
            }
        }
    })
    main_server.net_box:eval([[
        local metrics = require('cartridge.roles.metrics')
        metrics.set_default_labels(...)
    ]], {{
        app_name = 'myapp',
    }})

    reload_roles()

    local resp = main_server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    for _, obs in pairs(resp.json) do
        t.assert_equals(obs.label_pairs.system, 'some-system')
        t.assert_equals(obs.label_pairs.app_name, 'myapp')
        t.assert_equals(obs.label_pairs.alias, 'main')
    end
end

g.test_cartridge_hotreload_not_reset_collectors = function()
    local main_server = g.cluster:server('main')

    main_server:exec(function()
        local metrics = require('cartridge').service_get('metrics')
        metrics.counter('hotreload_checker'):inc(1)
    end)

    upload_config()
    local resp = main_server:http_request('get', '/new-metrics')
    t.assert_equals(resp.status, 200)

    local obs = utils.find_obs('hotreload_checker',  {alias = 'main', app_name = 'myapp'}, resp.json)
    t.assert_covers(obs, {
        label_pairs = {alias = 'main', app_name = 'myapp'},
        metric_name = 'hotreload_checker',
        value = 1,
    })

    reload_roles()

    main_server = g.cluster:server('main')
    resp = main_server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    obs = utils.find_obs('hotreload_checker',  {alias = 'main', app_name = 'myapp'}, resp.json)
    t.assert_covers(obs, {
        label_pairs = {alias = 'main', app_name = 'myapp'},
        metric_name = 'hotreload_checker',
        value = 1,
    })
end
