#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('collectors')

local metrics = require('metrics')
local utils = require('test.utils')

g.before_all(utils.create_server)
g.after_all(utils.drop_server)

g.after_each(function(cg)
    -- Delete all collectors and global labels
    metrics.clear()
    cg.server:exec(function()
        require('metrics').clear()
    end)
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

g.test_default_metrics_clear = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics') -- luacheck: ignore 431

        metrics.clear()
        metrics.enable_default_metrics()
        t.assert_equals(#metrics.collect(), 0)

        t.assert(#metrics.collect{invoke_callbacks = true} > 0)

        metrics.clear()
        t.assert_equals(#metrics.collect(), 0)
        t.assert_equals(#metrics.collect{invoke_callbacks = true}, 0)

        metrics.enable_default_metrics()
        t.assert(#metrics.collect{invoke_callbacks = true} > 0)
    end)
end

g.test_hotreload_remove_callbacks = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics') -- luacheck: ignore 431
        local utils = require('test.utils') -- luacheck: ignore 431

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
    end)
end

g.test_hotreload_old_registry_gets_filter = function(cg)
    cg.server:exec(function()
        local previous_registry = rawget(_G, '__metrics_registry')
        local previous_metrics_api = package.loaded['metrics.api']
        local old_registry = {
            collectors = {},
            callbacks = {},
            label_pairs = {},
        }

        rawset(_G, '__metrics_registry', old_registry)
        package.loaded['metrics.api'] = nil

        local metrics_api = require('metrics.api')
        local registry = rawget(_G, '__metrics_registry')

        t.assert_equals(registry, old_registry)
        t.assert_not_equals(registry.filter, nil)
        t.assert_equals(registry.filter, {
            include_all = true,
            include = {},
            exclude_all = false,
            exclude = {},
        })

        metrics_api.set_filter({{selector = 'roles.crud-router'}}, {})
        t.assert_equals(registry.filter, {
            include_all = false,
            include = {'roles.crud-router'},
            exclude_all = false,
            exclude = {},
        })

        rawset(_G, '__metrics_registry', previous_registry)
        package.loaded['metrics.api'] = previous_metrics_api
    end)
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

g.test_filter_custom_collectors = function()
    local crud = metrics.namespace('roles.crud-router')
    local queue = metrics.namespace('roles.queue')

    local crud_requests = crud:gauge('crud_requests')
    crud_requests:set(1)
    queue:gauge('queue_requests'):set(2)
    metrics.gauge('ungrouped_requests'):set(3)

    t.assert_equals(crud_requests.metainfo, {
        selector = 'roles.crud-router.crud_requests',
    })

    metrics.set_filter({{selector = 'roles.crud-router'}}, {})

    local observations = metrics.collect()
    t.assert_not_equals(utils.find_metric('crud_requests', observations), nil)
    t.assert_equals(utils.find_metric('queue_requests', observations), nil)
    t.assert_equals(utils.find_metric('ungrouped_requests', observations), nil)
end

g.test_filter_custom_collectors_exclude_has_priority = function()
    local crud = metrics.namespace('roles.crud-router')

    crud:gauge('crud_requests'):set(1)
    crud:gauge('crud_errors'):set(2)

    metrics.set_filter({{selector = 'roles.crud-router'}},
                       {{selector = 'roles.crud-router.crud_errors'}})

    local observations = metrics.collect()
    t.assert_not_equals(utils.find_metric('crud_requests', observations), nil)
    t.assert_equals(utils.find_metric('crud_errors', observations), nil)
end

g.test_filter_can_be_reconfigured = function()
    local crud = metrics.namespace('roles.crud-router')
    local queue = metrics.namespace('roles.queue')

    crud:gauge('crud_requests'):set(1)
    queue:gauge('queue_requests'):set(1)

    metrics.set_filter({{selector = 'roles.crud-router'}}, {})
    local observations = metrics.collect()
    t.assert_not_equals(utils.find_metric('crud_requests', observations), nil)
    t.assert_equals(utils.find_metric('queue_requests', observations), nil)

    metrics.set_filter({{selector = 'roles.queue'}}, {})
    observations = metrics.collect()
    t.assert_equals(utils.find_metric('crud_requests', observations), nil)
    t.assert_not_equals(utils.find_metric('queue_requests', observations), nil)

    metrics.set_filter('all', {})
    observations = metrics.collect()
    t.assert_not_equals(utils.find_metric('crud_requests', observations), nil)
    t.assert_not_equals(utils.find_metric('queue_requests', observations), nil)
end

g.test_set_filter_validation = function()
    t.assert_error_msg_contains(
        "Metric selector filter string must be 'all' or 'none'",
        function()
            metrics.set_filter('roles.crud-router', {})
        end)

    t.assert_error_msg_contains(
        'Metric selector filter item must be a table with a non-empty ' ..
        'selector field',
        function()
            metrics.set_filter({{name = 'roles.crud-router'}}, {})
        end)

    local Registry = require('metrics.registry')
    local registry = Registry.new()

    t.assert_error_msg_contains(
        "Metric selector filter must be 'all', 'none', or an array of " ..
        'selector objects',
        function()
            registry:set_filter(42, {})
        end)
end

g.test_filter_custom_callbacks = function()
    local crud = metrics.namespace('roles.crud-router')
    local queue = metrics.namespace('roles.queue')
    local crud_gauge = crud:gauge('crud_callback_runs')
    local queue_gauge = queue:gauge('queue_callback_runs')
    local crud_runs = 0
    local queue_runs = 0

    crud_gauge:set(0)
    queue_gauge:set(0)
    metrics.register_callback(function()
        crud_runs = crud_runs + 1
        crud_gauge:set(crud_runs)
    end, {selector = 'roles.crud-router'})
    metrics.register_callback(function()
        queue_runs = queue_runs + 1
        queue_gauge:set(queue_runs)
    end, {selector = 'roles.queue'})

    metrics.set_filter({{selector = 'roles.crud-router'}}, {})

    local observations = metrics.collect({invoke_callbacks = true})
    local crud_obs = utils.find_metric('crud_callback_runs', observations)
    local queue_obs = utils.find_metric('queue_callback_runs', observations)

    t.assert_equals(crud_obs[1].value, 1)
    t.assert_equals(queue_obs, nil)
    t.assert_equals(crud_runs, 1)
    t.assert_equals(queue_runs, 0)
end

g.test_collectors_are_filtered = function()
    local crud = metrics.namespace('roles.crud-router')
    local queue = metrics.namespace('roles.queue')

    crud:gauge('crud_requests'):set(1)
    queue:gauge('queue_requests'):set(2)

    metrics.set_filter('all', {{selector = 'roles.queue'}})

    local collectors = metrics.collectors()
    t.assert_not_equals(collectors.crud_requestsgauge, nil)
    t.assert_equals(collectors.queue_requestsgauge, nil)
end

g.test_default_metrics_metainfo = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics') -- luacheck: ignore 431
        metrics.enable_default_metrics()
        metrics.invoke_callbacks()

        for k, c in pairs(metrics.collectors()) do
            t.assert_equals(c.metainfo.default, true,
                ('default collector %s has metainfo label "default"'):format(k))
        end
    end)
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
    g['test_collect_default_only_' .. name] = function(cg)
        cg.server:exec(function(case) -- luacheck: ignore 433
            local metrics = require('metrics') -- luacheck: ignore 431
            local utils = require('test.utils') -- luacheck: ignore 431

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
        end, {case})
    end
end

g.test_version = function()
    t.assert_type(require('metrics')._VERSION, 'string')
end

g.test_deprecated_version = function(cg)
    cg.server:exec(function()
        t.assert_type(require('metrics').VERSION, 'string')
    end)

    local warn = "require%('metrics'%).VERSION is deprecated, " ..
        "use require%('metrics'%)._VERSION instead."
    t.assert_not_equals(cg.server:grep_log(warn), nil)
end
