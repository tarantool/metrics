#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('enable_default_metrics')

local utils = require('test.utils')

g.before_all(utils.create_server)
g.after_all(utils.drop_server)

g.after_each(function(cg)
    cg.server:exec(function()
        require('metrics').clear()
    end)
end)

local cases = {
    default = {
        include = nil,
        exclude = nil,
        expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
        not_expected = {},
    },
    include_all = {
        include = 'all',
        exclude = nil,
        expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
        not_expected = {},
    },
    include_list = {
        include = { 'info', 'memory' },
        exclude = nil,
        expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
        },
        not_expected = {
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
    },
    include_none = {
        include = 'none',
        exclude = nil,
        expected = {},
        not_expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
    },
    exclude_from_all = {
        include = 'all',
        exclude = { 'memory' },
        expected = {
            'tnt_info_uptime', 'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
        not_expected = {
            'tnt_info_memory_lua',
        },
    },
    exclude_from_list = {
        include = { 'info', 'memory', 'network' },
        exclude = { 'network', 'memory' },
        expected = {
            'tnt_info_uptime',
        },
        not_expected = {
            'tnt_info_memory_lua', 'tnt_net_sent_total',
        },
    },
    exclude_not_enabled = {
        include = { 'info' },
        exclude = { 'memory' },
        expected = {
            'tnt_info_uptime',
        },
        not_expected = {
            'tnt_info_memory_lua',
        },
    },
    tt3_cfg_include_all = {
        include = { 'all' },
        exclude = nil,
        expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
        not_expected = {},
    },
    tt3_cfg_exclude_all = {
        include = nil,
        exclude = { 'all' },
        expected = {},
        not_expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
    },
    tt3_cfg_exclude_from_include_all = {
        include = { 'all' },
        exclude = { 'memory' },
        expected = {
            'tnt_info_uptime', 'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
        not_expected = {
            'tnt_info_memory_lua',
        },
    },
    tt3_cfg_include_some_exclude_all = {
        include = { 'memory' },
        exclude = { 'all' },
        expected = {},
        not_expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
    },
    tt3_cfg_include_exclude_all = {
        include = { 'all' },
        exclude = { 'all' },
        expected = {},
        not_expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
    },
    tt3_cfg_include_all_and_specific = {
        include = { 'memory', 'all' },
        exclude = nil,
        expected = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        },
        not_expected = {},
    },
}

local methods = {
    [''] = {lib = 'metrics', func = 'enable_default_metrics'},
    v2_ = {lib = 'metrics.tarantool', func = 'enable_v2'},
}

for prefix, method in pairs(methods) do
    for name, case in pairs(cases) do
        g['test_' .. prefix .. name] = function(cg)
            cg.server:exec(function(method, case) -- luacheck: ignore 433
                local metrics = require('metrics')
                local utils = require('test.utils') -- luacheck: ignore 431

                require(method.lib)[method.func](case.include, case.exclude)

                local observations = metrics.collect{invoke_callbacks = true}

                for _, expected in ipairs(case.expected) do
                    local obs = utils.find_metric(expected, observations)
                    t.assert_not_equals(obs, nil, ("metric %q found"):format(expected))
                end

                for _, not_expected in ipairs(case.not_expected) do
                    local obs = utils.find_metric(not_expected, observations)
                    t.assert_equals(obs, nil, ("metric %q not found"):format(not_expected))
                end
            end, {method, case})
        end
    end
end

g.test_invalid_include = function(cg)
    cg.server:exec(function()
        t.assert_error_msg_contains(
            'Unexpected value provided: include must be "all", {...} or "none"',
            require('metrics').enable_default_metrics, 'everything')
    end)
end

g.test_v2_invalid_include = function(cg)
    cg.server:exec(function()
        t.assert_error_msg_contains(
            'Unexpected value provided: include must be "all", {...} or "none"',
            require('metrics.tarantool').enable_v2, 'everything')
    end)
end

local deprecated_cases = {
    include_unknown = {
        include = { 'http' },
        warn = 'Unknown metrics "http" provided, this will raise an error in the future',
        err = 'Unknown metrics "http" provided',
    },
    exclude_unknown = {
        exclude = { 'http' },
        warn = 'Unknown metrics "http" provided, this will raise an error in the future',
        err = 'Unknown metrics "http" provided',
    },
}

for name, case in pairs(deprecated_cases) do
    g['test_' .. name] = function(cg)
        cg.server:exec(function(case) -- luacheck: ignore 433
            require('metrics').enable_default_metrics(case.include, case.exclude)
        end, {case})

        t.assert_not_equals(cg.server:grep_log(case.warn), nil)
    end

    g['test_v2_' .. name] = function(cg)
        cg.server:exec(function(case) -- luacheck: ignore 433
            t.assert_error_msg_contains(
                case.err,
                require('metrics.tarantool').enable_v2, case.include, case.exclude)
        end, {case})
    end
end

g.test_empty_table_in_v1 = function(cg)
    cg.server:exec(function()
        require('metrics').enable_default_metrics({})
    end)

    -- local warn = 'Providing {} in enable_default_metrics include is treated ' ..
    --     'as a default value now (i.e. include all), ' ..
    --     'but it will change in the future. Use "all" instead'
    local warn = 'Providing {} in enable_default_metrics include is treated ' ..
        'as a default value now %(i.e. include all%), ' ..
        'but it will change in the future. Use "all" instead'
    t.assert_not_equals(cg.server:grep_log(warn), nil)

    g.server:exec(function()
        local metrics = require('metrics')
        local utils = require('test.utils') -- luacheck: ignore 431

        local observations = metrics.collect{invoke_callbacks = true}

        local expected_metrics = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        }

        for _, expected in ipairs(expected_metrics) do
            local obs = utils.find_metric(expected, observations)
            t.assert_not_equals(obs, nil, ("metric %q found"):format(expected))
        end
    end)
end

g.test_empty_table_in_v2 = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local utils = require('test.utils') -- luacheck: ignore 431

        require('metrics.tarantool').enable_v2({})

        local observations = metrics.collect{invoke_callbacks = true}

        local unexpected_metrics = {
            'tnt_info_uptime', 'tnt_info_memory_lua',
            'tnt_net_sent_total', 'tnt_slab_arena_used',
        }

        for _, expected in ipairs(unexpected_metrics) do
            local obs = utils.find_metric(expected, observations)
            t.assert_equals(obs, nil, ("metric %q not found"):format(expected))
        end
    end)
end
