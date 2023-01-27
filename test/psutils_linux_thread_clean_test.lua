#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('psutils_linux_clean_info')
local utils = require('test.utils')
local metrics = require('metrics')
local cpu = require('metrics.psutils.cpu')

g.before_all(function()
    t.skip_if(jit.os ~= 'Linux', 'Linux is the only supported platform')
    utils.init()
end)

g.after_each(function()
    metrics.clear()
end)

g.test_clean_thread_info = function()
    cpu.update()
    local observations = metrics.collect()

    local thread_obs = utils.find_metric('tnt_cpu_thread', observations)
    t.assert_not_equals(thread_obs, nil)

    local threads = {}
    for _, obs in ipairs(thread_obs) do
        threads[obs.label_pairs.thread_name] = true
    end

    -- After box.cfg{}, there should be at least tx (tarantool), iproto and wal.
    t.assert_ge(utils.len(threads), 3)
    t.assert_equals(#thread_obs, 2 * utils.len(threads),
        'There are two observations for each thread (user and system)')
end

g.test_cpu_count = function()
    cpu.update()
    local observations = metrics.collect()
    local metric = utils.find_metric('tnt_cpu_number', observations)
    t.assert_not_equals(metric, nil)
    t.assert_equals(#metric, 1)
    t.assert_gt(metric[1].value, 0)
end

local function check_cpu_metrics(presents)
    local observations = metrics.collect()

    local expected = {
        'tnt_cpu_number',
        'tnt_cpu_time',
        'tnt_cpu_thread',
    }

    for _, metric_name in ipairs(expected) do
        local metric = utils.find_metric(metric_name, observations)

        if presents then
            t.assert_not_equals(metric, nil)
        else
            t.assert_equals(metric, nil)
        end
    end
end

g.test_clear = function()
    cpu.update()
    check_cpu_metrics(true)

    cpu.clear()
    check_cpu_metrics(false)

    cpu.update()
    check_cpu_metrics(true)
end

g.test_default_metrics_metainfo = function()
    cpu.update()

    for k, c in pairs(metrics.collectors()) do
        t.assert_equals(c.metainfo.default, true,
            ('psutils collector %s has metainfo label "default"'):format(k))
    end
end
