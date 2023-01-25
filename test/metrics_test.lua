#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('collectors')

local metrics = require('metrics')
local utils = require('test.utils')

g.before_all(utils.init)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_global_labels = function()
    t.assert_error_msg_contains("bad label key (string expected, got number)", function()
        metrics.set_global_labels({ [2] = 'value' })
    end)

    --- Set correct global label
    metrics.set_global_labels({ alias = 'my_instance' })

    --- Ensure global label appends to counter observations
    local counter = metrics.counter('counter', 'test counter')

    -- Make some observation
    counter:inc(3)

    -- Collect metrics and check their labels
    local observations = metrics.collect()
    local obs_cnt = utils.find_obs('counter', { alias = "my_instance" }, observations)
    t.assert_equals(obs_cnt.value, 3, "observation has global label")


    --- Ensure global label appends to gauge observations
    local gauge = metrics.gauge('gauge', 'test gauge')

    -- Make some observation
    gauge:set(0.42)

    -- Collect metrics and check their labels
    observations = metrics.collect()
    local obs_gauge = utils.find_obs('gauge', { alias = 'my_instance' }, observations)
    t.assert_equals(obs_gauge.value, 0.42, "observation has global label")


    --- Ensure global label appends to every histogram observation
    local hist = metrics.histogram('hist', 'test histogram', {2})

    -- Make some observation
    hist:observe(3)

    -- Collect metrics and check their labels
    observations = metrics.collect()

    local obs_sum = utils.find_obs('hist_sum', { alias = "my_instance" }, observations)
    t.assert_equals(obs_sum.value, 3, "only one observed value 3; observation has global label")

    local obs_count = utils.find_obs('hist_count', { alias = "my_instance" }, observations)
    t.assert_equals(obs_count.value, 1, "1 observed value; observation has global label")

    local obs_bucket_2 = utils.find_obs('hist_bucket',
        { le = 2, alias = "my_instance" }, observations)
    t.assert_equals(obs_bucket_2.value, 0, "bucket 2 has no values; observation has global label")

    local obs_bucket_inf = utils.find_obs('hist_bucket',
        { le = metrics.INF, alias = "my_instance" }, observations)
    t.assert_equals(obs_bucket_inf.value, 1, "bucket +inf has 1 value: 3; observation has global label")


    --- Ensure global label merges with argument labels
    local gauge_2 = metrics.gauge('gauge 2', 'test gauge 2')

    -- Make some observation with label
    gauge_2:set(0.43, { mylabel = 'my observation' })

    -- Collect metrics and check their labels
    observations = metrics.collect()

    local obs_gauge_2 = utils.find_obs('gauge 2', { alias = 'my_instance', mylabel = 'my observation' }, observations)
    t.assert_equals(obs_gauge_2.value, 0.43, "observation has global label")


    --- Ensure label passed as argument overwrites global one
    local gauge_3 = metrics.gauge('gauge 3', 'test gauge 3')

    -- Make some observation with "alias" label key
    -- metrics.set_global_labels({ alias = 'my_instance' })
    gauge_3:set(0.44, { alias = 'gauge alias' })

    -- Collect metrics and check their labels
    observations = metrics.collect()
    local obs_gauge_3 = utils.find_obs('gauge 3', { alias = 'gauge alias' }, observations)
    t.assert_equals(obs_gauge_3.value, 0.44, "global label has not overwritten local one")


    --- Ensure we can change global labels along the way
    local hist_2 = metrics.histogram('hist_2', 'test histogram 2', {3})

    -- Make some observation
    hist_2:observe(2)
    -- Change global labels
    metrics.set_global_labels({ alias = 'another alias', nlabel = 3 })

    -- Collect metrics and check their labels
    observations = metrics.collect()

    local obs_sum_hist_2 = utils.find_obs('hist_2_sum',
        { alias = 'another alias', nlabel = 3 }, observations)
    t.assert_equals(obs_sum_hist_2.value, 2, "only one observed value 2; observation global label has changed")

    local obs_sum_count_2 = utils.find_obs('hist_2_count',
        { alias = 'another alias', nlabel = 3 }, observations)
    t.assert_equals(obs_sum_count_2.value, 1, "1 observed value; observation global label has changed")

    local obs_bucket_3_hist_2 = utils.find_obs('hist_2_bucket',
        { le = 3, alias = 'another alias', nlabel = 3 }, observations)
    t.assert_equals(obs_bucket_3_hist_2.value, 1, "bucket 3 has 1 value: 2; observation global label has changed")

    local obs_bucket_inf_hist_2 = utils.find_obs('hist_2_bucket',
        { le = metrics.INF, alias = 'another alias', nlabel = 3 }, observations)
    t.assert_equals(obs_bucket_inf_hist_2.value, 1, "bucket +inf has 1 value: 2; observation global label has changed")
end

g.test_default_metrics_clear = function()
    metrics.clear()
    metrics.enable_default_metrics()
    t.assert_equals(#metrics.collect(), 0)

    t.assert(#metrics.collect{invoke_callbacks = true} > 0)

    metrics.clear()
    t.assert_equals(#metrics.collect(), 0)
    t.assert_equals(#metrics.collect{invoke_callbacks = true}, 0)

    metrics.enable_default_metrics()
    t.assert(#metrics.collect{invoke_callbacks = true} > 0)
end

g.test_hotreload_remove_callbacks = function()
    metrics.enable_default_metrics()

    local Registry = rawget(_G, '__metrics_registry')
    local len_before_hotreload = utils.len(Registry.callbacks)
    t.assert_gt(len_before_hotreload, 0)

    package.loaded['metrics'] = nil

    metrics = require('metrics')
    metrics.enable_default_metrics()

    Registry = rawget(_G, '__metrics_registry')
    local len_after_hotreload = utils.len(Registry.callbacks)

    t.assert_equals(len_before_hotreload, len_after_hotreload)
end

local collect_invoke_callbacks_cases = {
    default = {
        args = nil,
        value = 0,
    },
    ['true'] = {
        args = {invoke_callbacks = true},
        value = 1,
    },
    ['false'] = {
        args = {invoke_callbacks = false},
        value = 0,
    },
}

for name, case in pairs(collect_invoke_callbacks_cases) do
    g['test_collect_invoke_callbacks_' .. name] = function()
        local c = metrics.counter('mycounter')

        local callback = function()
            c:inc()
        end
        metrics.register_callback(callback)

        -- Initialize a value in the registry.
        -- Otherwise collector would be empty.
        c:reset()

        local observations = metrics.collect(case.args)
        local obs = utils.find_obs('mycounter', {}, observations)
        t.assert_equals(obs.value, case.value)
    end
end
