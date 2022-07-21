local fio = require('fio')
local t = require('luatest')
local g = t.group()

local utils = require('test.utils')
local helpers = require('test.helper')

g.before_each(function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    g.cluster = helpers.init_cluster()
    helpers.upload_default_metrics_config(g.cluster)
end)

g.after_each(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end)

g.test_cartridge_issues_present_on_healthy_cluster = function()
    helpers.skip_cartridge_version_less('2.0.2')
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
    helpers.skip_cartridge_version_less('2.0.2')
    helpers.skip_cartridge_version_greater('2.5.0')
    local main_server = g.cluster:server('main')
    local replica_server = g.cluster:server('replica')

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
        local resp = main_server:http_request('get', '/metrics')
        local issues_metric = utils.find_metric('tnt_cartridge_issues', resp.json)[1]
        t.assert_equals(issues_metric.value, 1, [[
          Issues count is one cause main instance should has one replication issue:
          replication from main to replica is stopped.
        ]])
        t.assert_equals(issues_metric.label_pairs.level, 'warning')
    end)
end

g.test_cartridge_issues_metric_critical = function()
    helpers.skip_cartridge_version_less('2.0.2')
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

g.test_clock_delta_metric_present = function()
    local main_server = g.cluster:server('main')

    t.helpers.retrying({}, function()
        local resp = main_server:http_request('get', '/metrics')
        local clock_delta_metrics = utils.find_metric('tnt_clock_delta', resp.json)
        t.assert_equals(#clock_delta_metrics, 2)
        t.assert_equals(clock_delta_metrics[1].label_pairs.delta, 'max')
        t.assert_equals(clock_delta_metrics[2].label_pairs.delta, 'min')
    end)
end

g.test_read_only = function()
    local main_server = g.cluster:server('main')

    local resp = main_server:http_request('get', '/metrics')
    local read_only = utils.find_metric('tnt_read_only', resp.json)
    t.assert_equals(read_only[1].value, 0)

    local replica_server = g.cluster:server('replica')
    resp = replica_server:http_request('get', '/metrics')
    read_only = utils.find_metric('tnt_read_only', resp.json)
    t.assert_equals(read_only[1].value, 1)
end

g.test_failover = function()
    helpers.skip_cartridge_version_less('2.7.5')
    local main_server = g.cluster:server('main')

    local resp = main_server:http_request('get', '/metrics')
    local failover_trigger_cnt = utils.find_metric('tnt_cartridge_failover_trigger', resp.json)
    t.assert_equals(failover_trigger_cnt[1].value, 0)
end
