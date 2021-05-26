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
                    path = '/metrics',
                    format = 'json'
                },
            },
        }
    })
end

local function check_cartridge_version()
    -- Issues introduced in Cartridge 2.0.2
    local cartridge_version = require('cartridge.VERSION')
    t.skip_if(cartridge_version == 'unknown', 'Cartridge version is unknown, must be v2.0.2 or greater')
    t.skip_if(utils.is_version_less(cartridge_version, '2.0.2'), 'Cartridge version is must be v2.0.2 or greater')
end

local function check_cartridge_less_250()
    -- Issues introduced in Cartridge 2.0.2
    local cartridge_version = require('cartridge.VERSION')
    t.skip_if(cartridge_version == 'unknown', 'Cartridge version is unknown, must be v2.0.2 or greater')
    t.skip_if(utils.is_version_greater(cartridge_version, '2.5.0'), 'Cartridge version is must be v2.5.0 or less')
end

g.test_cartridge_issues_present_on_healthy_cluster = function()
    check_cartridge_version()
    upload_config()
    local main_server = g.cluster:server('main')
    local resp = main_server:http_request('get', '/metrics')
    local issues_metric = utils.find_metric('tnt_cartridge_issues', resp.json)
    t.assert_is_not(issues_metric, nil, 'Cartridge issues metric presents in /metrics response')

    t.helpers.retrying({}, function()
        resp = main_server:http_request('get', '/metrics')
        issues_metric = utils.find_metric('tnt_cartridge_issues', resp.json)
        for _, v in ipairs(issues_metric) do
            t.assert_equals(v.value, 0, 'Issues count is zero cause new-built cluster should be healthy')
        end
    end)
end

g.test_cartridge_issues_metric_warning = function()
    check_cartridge_version()

    local main_server = g.cluster:server('main')
    local replica_server = g.cluster:server('replica')
    upload_config()

    -- Stage replication issue "Duplicate key exists in unique index 'primary' in space '_space'"
    main_server.net_box:eval([[
        __replication = box.cfg.replication
        box.cfg{replication = box.NULL}
    ]])
    replica_server.net_box:eval([[
        box.cfg{read_only = false}
        box.schema.space.create('test')
    ]])
    main_server.net_box:eval([[
        box.schema.space.create('test')
        pcall(box.cfg, {replication = __replication})
        __replication = nil
    ]])
    
    t.helpers.retrying({}, function()
        check_cartridge_less_250()
        local resp = main_server:http_request('get', '/metrics')
        local issues_metric = utils.find_metric('tnt_cartridge_issues', resp.json)[1]
        t.assert_equals(issues_metric.value, 2, [[
          Issues count is two cause cluster should has two replication issues:
          replication from main to replica is stopped and
          replication from replica to main is stopped.
        ]])
        t.assert_equals(issues_metric.label_pairs.level, 'warning')
    end)
end

g.test_cartridge_issues_metric_critical = function()
    check_cartridge_version()
    upload_config()
    local main_server = g.cluster:server('main')

    main_server.net_box:eval([[
        box.slab.info = function()
            return {
                items_used = 99,
                items_size = 100,
                arena_used = 99,
                arena_size = 100,
                quota_used = 99,
                quota_size = 100,
            }
        end
    ]])

    t.helpers.retrying({}, function()
        local resp = main_server:http_request('get', '/metrics')
        local issues_metric = utils.find_metric('tnt_cartridge_issues', resp.json)[2]
        t.assert_equals(issues_metric.value, 1)
        t.assert_equals(issues_metric.label_pairs.level, 'critical')
    end)
end
