local fio = require('fio')
local t = require('luatest')
local g = t.group()

local helpers = require('test.helper')

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

local function assert_counter(name)
    local server = g.cluster.main_server
    g.cluster.main_server.net_box:eval([[
        local cartridge = require('cartridge')
        local metrics = cartridge.service_get('metrics')
        metrics.counter(...):inc(1)
    ]], {name})

    local counter_present = false

    local resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
    for _, obs in pairs(resp.json) do
        t.assert_equals(
            g.cluster.main_server.alias, obs.label_pairs['alias'],
            ('Alias label is present in metric %s'):format(obs.metric_name)
        )
        if obs.metric_name == name then
            counter_present = true
            t.assert_equals(obs.value, 1)
        end
    end
    t.assert(counter_present)
end

local function assert_bad_config(config, error)
    local server = g.cluster.main_server
    local resp = server:http_request('put', '/admin/config', {
        body = yaml.encode(config),
        raise = false
    })
    t.assert_str_icontains(resp.json.err, error)
end

local function assert_set_export(path)
    local ret = set_export({
        {
            path = path,
            format = 'json',
        },
    })
    t.assert_not(ret)
end

local function assert_upload_metrics_config(path)
    local server = g.cluster.main_server
    local resp = server:upload_config({
        metrics = {
            export = {
                {
                    path = path,
                    format = 'json'
                },
            },
        }
    })
    t.assert_equals(resp.status, 200)
end


g.before_each(function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    g.cluster = helpers.Cluster:new({
        datadir = fio.tempdir(),
        server_command = helpers.entrypoint('srv_basic'),
        replicasets = {
            {
                uuid = helpers.uuid('a'),
                roles = {},
                servers = {
                    {instance_uuid = helpers.uuid('a', 1), alias = 'main'},
                },
            },
        },
    })
    g.cluster:start()
end)

g.after_each( function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end )

g.after_all = function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end

g.test_role_enabled = function()
    local resp = g.cluster.main_server.net_box:eval([[
        local cartridge = require('cartridge')
        return cartridge.service_get('metrics') == nil
    ]])
    t.assert_equals(resp, false)
end

g.test_role_add_metrics_http_endpoint = function()
    local server = g.cluster.main_server
    local resp = server:upload_config({
        metrics = {
            export = {
                {
                    path = '/metrics',
                    format = 'json'
                },
            },
        }
    })
    t.assert_equals(resp.status, 200)
    assert_counter('test-upload')
    resp = server:upload_config({
        metrics = {
            export = {
                {
                    path = '/new-metrics',
                    format = 'json'
                },
            },
        }
    })
    t.assert_equals(resp.status, 200)
    resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 404)
    resp = server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    resp = server:upload_config({
        metrics = {
            export = {}
        }
    })
    t.assert_equals(resp.status, 200)
    resp = server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 404)

end

g.test_validate_config_invalid_export_section = function()
    assert_bad_config({
        metrics = {
            export = '/metrics',
        },
    }, 'bad argument')
end

g.test_validate_config_invalid_export_format = function()
    assert_bad_config({
        metrics = {
            export = {
                {
                    path = '/valid-path',
                    format = 'invalid-format'
                },
            },
        }
    }, 'format must be "json", "prometheus" or "health"')
end

g.test_validate_config_duplicate_paths = function()
    assert_bad_config({
        metrics = {
            export = {
                {
                    path = '/metrics',
                    format = 'json'
                },
                {
                    path = '/metrics',
                    format = 'prometheus'
                },
            },
        }
    }, 'paths must be unique')

    assert_bad_config({
        metrics = {
            export = {
                {
                    path = '/metrics',
                    format = 'json'
                },
                {
                    path = 'metrics/',
                    format = 'prometheus'
                },
            },
        }
    }, 'paths must be unique')

    assert_bad_config({
        metrics = {
            export = {
                {
                    path = '/metrics/',
                    format = 'json'
                },
                {
                    path = 'metrics',
                    format = 'prometheus'
                },
            },
        }
    }, 'paths must be unique')
end

g.test_set_export_add_metrics_http_endpoint = function()
    local server = g.cluster.main_server
    local ret = set_export({
        {
            path = '/metrics',
            format = 'json',
        },
    })
    t.assert_not(ret)
    assert_counter('test-set')
    ret = set_export({
        {
            path = '/new-metrics',
            format = 'json',
        },
    })
    t.assert_not(ret)
    local resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 404)
    resp = server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 200)

    ret = set_export({})
    t.assert_not(ret)
    resp = server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 404)
end

g.test_set_export_validates_input = function()
    local err = set_export({
        {
            path = '/valid-path',
            format = 'invalid-format'
        },
    })
    t.assert_str_icontains(err, 'format must be "json", "prometheus" or "health"')
end

g.test_empty_clusterwide_config_not_overrides_set_export = function()
    local server = g.cluster.main_server
    assert_set_export('/metrics')
    local resp = server:upload_config({})
    t.assert_equals(resp.status, 200)
    resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_non_empty_clusterwide_config_overrides_set_export = function()
    local server = g.cluster.main_server
    assert_upload_metrics_config('/metrics')
    assert_set_export('/new-metrics')
    assert_upload_metrics_config('/metrics')
    local resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
    resp = server:http_request('get', '/new-metrics', {raise = false})
    t.assert_equals(resp.status, 404)
end

g.test_set_export_from_require_role = function()
    local server = g.cluster.main_server
    server.net_box:eval([[
        local metrics = require('cartridge.roles.metrics')
        metrics.set_export(...)
    ]], {{
        {
            path = '/metrics',
            format = 'json',
        },
    }})
    local resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
end

local function set_zones(zones)
    local servers = {}
    for k, v in pairs(zones) do
        table.insert(servers, {uuid = k, zone = v})
    end
    return g.cluster.main_server.net_box:eval([[
        local servers = ...
        local ret, err = require('cartridge').admin_edit_topology({
            servers = servers,
        })
        if ret == nil then
            return nil, err
        end
        return true
    ]], {servers})
end

local function check_cartridge_version(version)
    local cartridge_version = require('cartridge.VERSION')
    t.skip_if(cartridge_version == 'unknown',
    'Cartridge version is unknown, must be 2.0.2 or greater')
    t.skip_if(utils.is_version_less(cartridge_version, version),
    string.format('Cartridge version is must be %s or greater', version))
end

g.test_zone_label_present = function()
    check_cartridge_version('2.4.0')
    local server = g.cluster.main_server

    local ok, err = set_zones({
        [server.instance_uuid] = 'z1',
    })
    t.assert_equals({ok, err}, {true, nil})
    assert_upload_metrics_config('/metrics')

    local resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
    for _, obs in pairs(resp.json) do
        t.assert_equals(
            'z1', obs.label_pairs['zone'],
            ('Alias label is present in metric %s'):format(obs.metric_name)
        )
    end
end

g.test_zone_label_changes_in_runtime = function()
    check_cartridge_version('2.4.0')
    local server = g.cluster.main_server
    assert_upload_metrics_config('/metrics')

    local ok, err = set_zones({
        [server.instance_uuid] = 'z2',
    })
    t.assert_equals({ok, err}, {true, nil})

    local resp = server:http_request('get', '/metrics', {raise = false})
    t.assert_equals(resp.status, 200)
    for _, obs in pairs(resp.json) do
        t.assert_equals(
            'z2', obs.label_pairs['zone'],
            ('Alias label is present in metric %s'):format(obs.metric_name)
        )
    end
end
