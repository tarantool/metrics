local t = require('luatest')
local group = t.group('cfg')

local fio = require('fio')

local metrics = require('metrics')
local utils = require('test.utils')

local root = fio.dirname(fio.dirname(fio.abspath(package.search('test.helper'))))

local function create_server(g)
    g.tmpdir = fio.tempdir()
    g.server = t.Server:new({
        command = fio.pathjoin(
            fio.dirname(debug.sourcedir()),
            'test', 'entrypoint', 'srv_basic_pure.lua'
        ),
        workdir = g.tmpdir,
        net_box_port = 3031,
        net_box_credentials = {user = 'guest', password = nil},
        env = {
            LUA_PATH = root .. '/?.lua;' ..
                root .. '/?/init.lua;' ..
                root .. '/.rocks/share/tarantool/?.lua'
        },
    })
    g.server:start()
    t.helpers.retrying({}, function() g.server:connect_net_box() end)
end

local function clean_server(g)
    g.server:stop()
    fio.rmtree(g.tmpdir)
end

group.before_all(utils.init)

group.before_each(function()
    -- Reset to defaults.
    metrics.cfg{
        include = 'all',
        exclude = {},
        labels = {},
    }
end)

group.before_test('test_default', create_server)

group.test_default = function(g)
    local cfg = g.server:eval([[
        local metrics = require('metrics')
        return metrics.cfg{}
    ]])

    t.assert_equals(cfg, {include = 'all', exclude = {}, labels = {}})

    local observations = g.server:eval([[
        local metrics = require('metrics')
        return metrics.collect{invoke_callbacks = true}
    ]])

    local expected_metrics = {
        'tnt_info_uptime', 'tnt_info_memory_lua',
        'tnt_net_sent_total', 'tnt_slab_arena_used',
    }

    for _, expected in ipairs(expected_metrics) do
        local obs = utils.find_metric(expected, observations)
        t.assert_not_equals(obs, nil, ("metric %q found"):format(expected))
    end
end

group.after_test('test_default', clean_server)

group.before_test('test_read_before_init', create_server)

group.test_read_before_init = function(g)
    t.assert_error_msg_contains(
        'Call metrics.cfg{} first',
        function()
            g.server:eval([[
                local metrics = require('metrics')
                return metrics.cfg.include
            ]])
        end)
end

group.after_test('test_read_before_init', clean_server)

group.test_table_value = function()
    metrics.cfg{
        include = {'info'}
    }
    t.assert_equals(metrics.cfg.include, {'info'})
end

group.test_change_value = function()
    local cfg = metrics.cfg{
        include = {'info'},
    }
    t.assert_equals(cfg['include'], {'info'})
end

group.test_table_is_immutable = function()
    t.assert_error_msg_contains(
        'Use metrics.cfg{} instead',
        function()
            metrics.cfg.include = {'info'}
        end
    )

    t.assert_error_msg_contains(
        'Use metrics.cfg{} instead',
        function()
            metrics.cfg.newfield = 'newvalue'
        end
    )
end

group.test_include = function()
    metrics.cfg{
        include = {'info'},
    }

    local default_metrics = metrics.collect{invoke_callbacks = true}
    local uptime = utils.find_metric('tnt_info_uptime', default_metrics)
    t.assert_not_equals(uptime, nil)
    local memlua = utils.find_metric('tnt_info_memory_lua', default_metrics)
    t.assert_equals(memlua, nil)
end

group.test_exclude = function()
    metrics.cfg{
        exclude = {'memory'},
    }

    local default_metrics = metrics.collect{invoke_callbacks = true}
    local uptime = utils.find_metric('tnt_info_uptime', default_metrics)
    t.assert_not_equals(uptime, nil)
    local memlua = utils.find_metric('tnt_info_memory_lua', default_metrics)
    t.assert_equals(memlua, nil)
end

group.test_include_with_exclude = function()
    metrics.cfg{
        include = {'info', 'memory'},
        exclude = {'memory'},
    }

    local default_metrics = metrics.collect{invoke_callbacks = true}
    local uptime = utils.find_metric('tnt_info_uptime', default_metrics)
    t.assert_not_equals(uptime, nil)
    local memlua = utils.find_metric('tnt_info_memory_lua', default_metrics)
    t.assert_equals(memlua, nil)
end

group.test_include_none = function()
    metrics.cfg{
        include = 'none',
        exclude = {'memory'},
    }

    local default_metrics = metrics.collect{invoke_callbacks = true}
    t.assert_equals(default_metrics, {})
end

group.test_labels = function()
    metrics.cfg{
        labels = {mylabel = 'myvalue'},
    }

    local default_metrics = metrics.collect{invoke_callbacks = true}
    local uptime = utils.find_obs('tnt_info_uptime', {mylabel = 'myvalue'}, default_metrics)
    t.assert_equals(uptime.label_pairs, {mylabel = 'myvalue'})

    metrics.cfg{
        labels = {},
    }

    default_metrics = metrics.collect{invoke_callbacks = true}
    uptime = utils.find_obs('tnt_info_uptime', {}, default_metrics)
    t.assert_equals(uptime.label_pairs, {})
end


