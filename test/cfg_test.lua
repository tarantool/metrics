local t = require('luatest')
local group = t.group('cfg')

local utils = require('test.utils')

local function is_metrics_configured_with_box_cfg(srv)
    return srv:eval([[
        if type(box.cfg) ~= 'table' then
            return false
        end

        return box.cfg.metrics ~= nil
    ]])
end

group.before_all(utils.create_server)

group.after_all(utils.drop_server)

group.before_each(function(g)
    -- Reset to defaults.
    g.server:exec(function()
        require('metrics').cfg{
            include = 'all',
            exclude = {},
            labels = {},
        }
    end)
end)

group.before_test('test_default', function(g)
    -- Need clean unconfigured server.
    utils.drop_server(g)
    utils.create_server(g)
end)

group.test_default = function(g)
    t.skip_if(
        is_metrics_configured_with_box_cfg(g.server),
        "Tarantool configures built-in metrics with box.cfg on its own, " ..
        "can't test clean instance"
    )

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

group.before_test('test_read_before_init', function(g)
    -- Need clean unconfigured server.
    utils.drop_server(g)
    utils.create_server(g)
end)

group.test_read_before_init = function(g)
    t.skip_if(
        is_metrics_configured_with_box_cfg(g.server),
        "Tarantool configures built-in metrics with box.cfg on its own, " ..
        "can't test clean instance"
    )

    t.assert_error_msg_contains(
        'Call metrics.cfg{} first',
        function()
            g.server:eval([[
                local metrics = require('metrics')
                return metrics.cfg.include
            ]])
        end)
end

group.test_table_value = function(g)
    g.server:exec(function()
        local metrics = require('metrics')
        metrics.cfg{
            include = {'info'}
        }
        t.assert_equals(metrics.cfg.include, {'info'})
    end)
end

group.test_change_value = function(g)
    g.server:exec(function()
        local metrics = require('metrics')
        local cfg = metrics.cfg{
            include = {'info'},
        }
        t.assert_equals(cfg['include'], {'info'})
    end)
end

group.test_table_is_immutable = function(g)
    g.server:exec(function()
        local metrics = require('metrics')

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
    end)
end

local matrix = {
    -- {category: string, includes: string, excludes: string, linux_only: boolean}
    {'info', 'tnt_info_uptime', 'tnt_info_memory_lua'},
    {'cpu_extended', 'tnt_cpu_thread', 'tnt_info_memory_lua', true},
    {'network', 'tnt_net_sent_total', 'tnt_info_memory_lua'},
    {'operations', 'tnt_stats_op_total', 'tnt_info_memory_lua'},
    {'system', 'tnt_cfg_current_time', 'tnt_info_memory_lua'},
    -- TODO: add more caterories
}

for _, row in ipairs(matrix) do
    local m_category, m_include, m_exclude, m_linux_only = unpack(row)

    group[('test_include_%s'):format(m_category)] = function(g)
        g.server:exec(function(category, include, exclude, linux_only)
            t.skip_if(linux_only and jit.os ~= 'Linux', 'Linux is the only supported platform')
            local metrics = require('metrics')
            local utils = require('test.utils') -- luacheck: ignore 431

            metrics.cfg{
                include = {category},
            }

            local default_metrics = metrics.collect{invoke_callbacks = true}
            local included = utils.find_metric(include, default_metrics)
            t.assert_not_equals(included, nil)
            local excluded = utils.find_metric(exclude, default_metrics)
            t.assert_equals(excluded, nil)
        end, {m_category, m_include, m_exclude, m_linux_only})
    end
    group[('test_exclude_%s'):format(m_category)] = function(g)
        g.server:exec(function(category, include, exclude, linux_only)
            t.skip_if(linux_only and jit.os ~= 'Linux', 'Linux is the only supported platform')
            local metrics = require('metrics')
            local utils = require('test.utils') -- luacheck: ignore 431

            metrics.cfg{
                exclude = {category},
            }

            local default_metrics = metrics.collect{invoke_callbacks = true}
            local uptime = utils.find_metric(exclude, default_metrics)
            t.assert_not_equals(uptime, nil)
            local memlua = utils.find_metric(include, default_metrics)
            t.assert_equals(memlua, nil)
        end, {m_category, m_include, m_exclude, m_linux_only})
    end
end

group.test_include_with_exclude = function(g)
    g.server:exec(function()
        local metrics = require('metrics')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.cfg{
            include = {'info', 'memory'},
            exclude = {'memory'},
        }

        local default_metrics = metrics.collect{invoke_callbacks = true}
        local uptime = utils.find_metric('tnt_info_uptime', default_metrics)
        t.assert_not_equals(uptime, nil)
        local memlua = utils.find_metric('tnt_info_memory_lua', default_metrics)
        t.assert_equals(memlua, nil)
    end)
end

group.test_include_none = function(g)
    g.server:exec(function()
        local metrics = require('metrics')

        metrics.cfg{
            include = 'none',
            exclude = {'memory'},
        }

        local default_metrics = metrics.collect{invoke_callbacks = true}
        t.assert_equals(default_metrics, {})
    end)
end

group.test_labels = function(g)
    g.server:exec(function()
        local metrics = require('metrics')
        local utils = require('test.utils') -- luacheck: ignore 431

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
    end)
end
