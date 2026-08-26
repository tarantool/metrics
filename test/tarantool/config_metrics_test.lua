local t = require('luatest')
local g = t.group()

local fio = require('fio')
local yaml = require('yaml')

local utils = require('test.utils')
local treegen = require('test.tarantool3_helpers.treegen')
local server_helper = require('test.tarantool3_helpers.server')

g.before_all(function(cg)
    cg.treegen = {}
    treegen.init(cg.treegen)
end)

g.after_all(function(cg)
    treegen.clean(cg.treegen)
end)


local default_config =  {
    credentials = {
        users = {
            guest = {
                roles = {'super'},
            },
            replicator = {
                password = 'replicating',
                roles = {'replication'},
            },
        },
    },
    iproto = {
        advertise = {
            peer = {
                login = 'replicator',
            },
        },
    },
    groups = {
        servers = {
            replicasets = {
                ['server-001'] = {
                    leader = 'server-001-a',
                    instances = {
                        ['server-001-a'] = {
                            iproto = {
                                listen = {{uri = 'localhost:3301'}},
                            },
                        },
                    },
                },
            },
        },
    },
    replication = {
        failover = 'manual',
    },
    metrics = {
        include = {'all'},
    },
}

local function write_config(cg, config)
    return treegen.write_script(cg.server_dir, 'config.yaml', yaml.encode(config))
end

local function start_server(cg)
    t.skip_if(not utils.is_tarantool_3_config_supported(),
              'Skip since Tarantool 3 config is unsupported')

    cg.server_dir = treegen.prepare_directory(cg.treegen, {}, {})
    local config_file = write_config(cg, default_config)

    cg.server = server_helper:new{
        alias = 'server-001-a',
        config_file = config_file,
        chdir = cg.server_dir,
    }
    cg.server:start{wait_until_ready = true}
end

local function stop_server(cg)
    if cg.server ~= nil then
        cg.server:stop()
        cg.server = nil
    end

    if cg.server_dir ~= nil then
        fio.rmtree(cg.server_dir)
        cg.server_dir = nil
    end
end

local function reload_config(cg, config)
    write_config(cg, config)
    cg.server:exec(function()
        pcall(function()
            require('config'):reload()
        end)
    end)
end

local function assert_config_alerts_metrics(server, expected_values)
    local observations = server:exec(function()
        local metrics = require('metrics')
        metrics.invoke_callbacks()
        return metrics.collect()
    end)

    local warnings = utils.find_obs(
        'tnt_config_alerts',
        {level = 'warn', alias = 'server-001-a'},
        observations
    )
    t.assert_equals(warnings.value, expected_values['warn'])

    local errors = utils.find_obs(
        'tnt_config_alerts',
        {level = 'error', alias = 'server-001-a'},
        observations
    )
    t.assert_equals(errors.value, expected_values['error'])
end

local function assert_config_status_metrics(server, expected_values)
    local observations = server:exec(function()
        local metrics = require('metrics')
        metrics.invoke_callbacks()
        return metrics.collect()
    end)

    for status, expected_value in pairs(expected_values) do
        local actual_obs = utils.find_obs(
            'tnt_config_status',
            {status = status, alias = 'server-001-a'},
            observations
        )
        t.assert_equals(actual_obs.value, expected_value,
                        ("got expected value for %q"):format(status))
    end
end


g.before_test('test_config_metrics_if_healthy', start_server)
g.after_test('test_config_metrics_if_healthy', stop_server)

g.test_config_metrics_if_healthy = function(cg)
    assert_config_alerts_metrics(cg.server, {warn = 0, error = 0})
    assert_config_status_metrics(cg.server, {
        uninitialized = 0,
        startup_in_progress = 0,
        reload_in_progress = 0,
        check_warnings = 0,
        check_errors = 0,
        ready = 1,
    })
end


g.before_test('test_config_metrics_if_minor_trouble', start_server)
g.after_test('test_config_metrics_if_minor_trouble', stop_server)

g.test_config_metrics_if_minor_trouble = function(cg)
    local config = table.deepcopy(default_config)
    config['credentials']['users']['user_one'] = {roles = {'role_two'}}
    reload_config(cg, config)

    assert_config_alerts_metrics(cg.server, {warn = 1, error = 0})
    assert_config_status_metrics(cg.server, {
        uninitialized = 0,
        startup_in_progress = 0,
        reload_in_progress = 0,
        check_warnings = 1,
        check_errors = 0,
        ready = 0,
    })
end


g.before_test('test_config_metrics_if_critical_failure', start_server)
g.after_test('test_config_metrics_if_critical_failure', stop_server)

g.test_config_metrics_if_critical_failure = function(cg)
    local config = table.deepcopy(default_config)
    config['groups']['servers'] = {}
    reload_config(cg, config)

    assert_config_alerts_metrics(cg.server, {warn = 0, error = 1})
    assert_config_status_metrics(cg.server, {
        uninitialized = 0,
        startup_in_progress = 0,
        reload_in_progress = 0,
        check_warnings = 0,
        check_errors = 1,
        ready = 0,
    })
end


g.before_test('test_config_metrics_if_uninitialized', function(cg)
    t.skip_if(not utils.is_tarantool_3_config_supported(),
              'Skip since Tarantool 3 config is unsupported')
    utils.create_server(cg)
    cg.server:exec(function()
        -- Config do it by default:
        -- https://github.com/tarantool/tarantool/blob/319357d5973d15d08b8eda6a230eada08b710802/src/box/lua/config/applier/box_cfg.lua#L614
        box.cfg{metrics = {labels = {alias = 'server-001-a'}}}
    end)
end)

g.after_test('test_config_metrics_if_uninitialized', function(cg)
    utils.drop_server(cg)
    cg.server = nil
end)

g.test_config_metrics_if_uninitialized = function(cg)
    assert_config_alerts_metrics(cg.server, {warn = 0, error = 0})
    assert_config_status_metrics(cg.server, {
        uninitialized = 1,
        startup_in_progress = 0,
        reload_in_progress = 0,
        check_warnings = 0,
        check_errors = 0,
        ready = 0,
    })
end


g.before_test('test_config_metrics_if_unsupported', function(cg)
    t.skip_if(utils.is_tarantool_3_config_supported(),
              'Skip since Tarantool 3 config is supported')
    utils.create_server(cg)
end)

g.after_test('test_config_metrics_if_unsupported', function(cg)
    utils.drop_server(cg)
    cg.server = nil
end)

g.test_config_metrics_if_unsupported = function(cg)
    local observations = cg.server:exec(function()
        local metrics = require('metrics')
        metrics.invoke_callbacks()
        return metrics.collect()
    end)

    local alerts = utils.find_metric('tnt_config_alerts', observations)
    t.assert_equals(alerts, nil)

    local status = utils.find_metric('tnt_config_status', observations)
    t.assert_equals(status, nil)
end
