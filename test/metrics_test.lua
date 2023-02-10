#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('collectors')

local luatest_capture = require('luatest.capture')

local metrics = require('metrics')
local utils = require('test.utils')

g.before_all(utils.init)

g.before_each(function()
    -- Reset to defaults.
    metrics.cfg{
        include = 'all',
        exclude = {},
        labels = {},
    }
end)

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

g.test_default_metrics_metainfo = function()
    metrics.enable_default_metrics()
    metrics.invoke_callbacks()

    for k, c in pairs(metrics.collectors()) do
        t.assert_equals(c.metainfo.default, true,
            ('default collector %s has metainfo label "default"'):format(k))
    end
end

local collect_default_only_cases = {
    default = {
        args = {invoke_callbacks = true},
        custom_expected = true,
    },
    ['true'] = {
        args = {invoke_callbacks = true, default_only = true},
        custom_expected = false,
    },
    ['false'] = {
        args = {invoke_callbacks = true, default_only = false},
        custom_expected = true,
    },
}

for name, case in pairs(collect_default_only_cases) do
    g['test_collect_default_only_' .. name] = function()
        metrics.enable_default_metrics()
        local c = metrics.gauge('custom_metric')
        c:set(42)

        local observations = metrics.collect(case.args)

        local default_obs = utils.find_metric('tnt_info_memory_lua', observations)
        t.assert_not_equals(default_obs, nil)

        local custom_obs = utils.find_metric('custom_metric', observations)
        if case.custom_expected then
            t.assert_not_equals(custom_obs, nil)
        else
            t.assert_equals(custom_obs, nil)
        end
    end
end

local control_characters_cases = {
    in_global_label_key = function()
        metrics.cfg{labels = {['lab\tval\tlab2'] = 'val2'}}
    end,
    in_global_label_value = function()
        metrics.cfg{labels = {lab = 'val\tlab2\tval2'}}
    end,
}

for name, case in pairs(control_characters_cases) do
    g['test_control_characters_' .. name .. 'are_not_expected'] = function()
        local capture = luatest_capture:new()
        capture:enable()

        case()

        local stdout = utils.fflush_main_server_output(nil, capture)
        capture:disable()

        t.assert_str_contains(
            stdout,
            'Do not use control characters, this will raise an error in the future.')
    end
end

g.test_collect_extended = function()
    local res_plain = metrics.collect{invoke_callbacks = true}
    local res_extended = metrics.collect{invoke_callbacks = true, extended_format=true}

    local count = 0
    for _, collector_obs in pairs(res_extended) do
        t.assert_type(collector_obs.name, 'string')
        t.assert_type(collector_obs.name_prefix, 'string')
        t.assert_type(collector_obs.kind, 'string')
        t.assert_type(collector_obs.help, 'string')
        t.assert_type(collector_obs.metainfo, 'table')
        t.assert_gt(collector_obs.timestamp, 0)
        t.assert_type(collector_obs.observations, 'table')

        for _, obs_group in pairs(collector_obs.observations) do
            count = count + utils.len(obs_group)
        end
    end

    t.assert_equals(count, #res_plain, "No observations lost in extended format")
end

local function observations_covers_by_key(res_1, res_2)
    for coll_key, coll_obs_1 in pairs(res_1) do
        t.assert_type(res_2[coll_key], 'table', "Collector info found")
        local coll_obs_2 = res_2[coll_key]
        t.assert_equals(coll_obs_1.name, coll_obs_2.name)
        t.assert_equals(coll_obs_1.kind, coll_obs_2.kind)

        for group_name, obs_group_1 in pairs(coll_obs_1.observations) do
            local obs_group_2 = coll_obs_2.observations[group_name]
            t.assert_type(obs_group_2, 'table', "Observation group found")
            for key, obs_1 in pairs(obs_group_1) do
                local obs_2 = obs_group_2[key]
                t.assert_type(obs_2, 'table', "Observation found")
                t.assert_equals(obs_1.label_pairs, obs_2.label_pairs)
            end
        end
    end
end

g.test_collect_extended_keys = function()
    local res_1 = metrics.collect{invoke_callbacks = true, extended_format=true}
    local res_2 = metrics.collect{invoke_callbacks = true, extended_format=true}

    observations_covers_by_key(res_1, res_2)
    observations_covers_by_key(res_2, res_1)
end
