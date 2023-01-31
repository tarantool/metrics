#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('enable_default_metrics')

local luatest_capture = require('luatest.capture')

local metrics = require('metrics')
local utils = require('test.utils')

g.before_all(utils.init)

g.after_each(function()
    metrics.clear()
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
}

for name, case in pairs(cases) do
    g['test_' .. name] = function()
        metrics.enable_default_metrics(case.include, case.exclude)

        local observations = metrics.collect{invoke_callbacks = true}

        for _, expected in ipairs(case.expected) do
            local obs = utils.find_metric(expected, observations)
            t.assert_not_equals(obs, nil, ("metric %q found"):format(expected))
        end

        for _, not_expected in ipairs(case.not_expected) do
            local obs = utils.find_metric(not_expected, observations)
            t.assert_equals(obs, nil, ("metric %q not found"):format(not_expected))
        end
    end
end

g.test_invalid_include = function()
    t.assert_error_msg_contains(
        'Unexpected value provided: include must be "all", {...} or "none"',
        metrics.enable_default_metrics, 'everything')
end

local deprecated_cases = {
    include_unknown = {
        include = { 'http' },
        warn = 'Unknown metrics "http" provided, this will raise an error in the future',
    },
    exclude_unknown = {
        exclude = { 'http' },
        warn = 'Unknown metrics "http" provided, this will raise an error in the future',
    },
}

for name, case in pairs(deprecated_cases) do
    g['test_' .. name] = function()
        local capture = luatest_capture:new()
        capture:enable()

        metrics.enable_default_metrics(case.include, case.exclude)
        local stdout = utils.fflush_main_server_output(nil, capture)
        capture:disable()

        t.assert_str_contains(stdout, case.warn)
    end
end

g.test_empty_table_in_v1 = function()
    local capture = luatest_capture:new()
    capture:enable()

    metrics.enable_default_metrics({})
    local stdout = utils.fflush_main_server_output(nil, capture)
    capture:disable()

    t.assert_str_contains(
        stdout,
        'Providing {} in enable_default_metrics include is treated ' ..
        'as a default value now (i.e. include all), ' ..
        'but it will change in the future. Use "all" instead')

    local observations = metrics.collect{invoke_callbacks = true}

    local expected_metrics = {
        'tnt_info_uptime', 'tnt_info_memory_lua',
        'tnt_net_sent_total', 'tnt_slab_arena_used',
    }

    for _, expected in ipairs(expected_metrics) do
        local obs = utils.find_metric(expected, observations)
        t.assert_not_equals(obs, nil, ("metric %q found"):format(expected))
    end
end
