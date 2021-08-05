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

local function len(tbl)
    local l = 0
    for _ in pairs(tbl) do
        l = l + 1
    end
    return l
end

g.test_counter = function()
    t.assert_error_msg_contains("bad argument #1 to counter (string expected, got nil)", function()
        metrics.counter()
    end)

    t.assert_error_msg_contains("bad argument #1 to counter (string expected, got number)", function()
        metrics.counter(2)
    end)

    local c = metrics.counter('cnt', 'some counter')

    c:inc(3)
    c:inc(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('cnt', {}, observations)
    t.assert_equals(len(collectors), 1, 'counter seen as only collector')
    t.assert_equals(obs.value, 8, '3 + 5 = 8 (via metrics.collectors())')

    t.assert_equals(c:collect()[1].value, 8, '3 + 5 = 8')

    t.assert_error_msg_contains("Counter increment should not be negative", function()
        c:inc(-1)
    end)

    t.assert_equals(c.dec, nil, "Counter doesn't have 'decrease' method")

    c:inc(0)
    t.assert_equals(c:collect()[1].value, 8, '8 + 0 = 8')
end

g.test_gauge = function()
    t.assert_error_msg_contains("bad argument #1 to gauge (string expected, got nil)", function()
        metrics.gauge()
    end)

    t.assert_error_msg_contains("bad argument #1 to gauge (string expected, got number)", function()
        metrics.gauge(2)
    end)

    local gauge = metrics.gauge('gauge', 'some gauge')

    gauge:inc(3)
    gauge:dec(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('gauge', {}, observations)
    t.assert_equals(len(collectors), 1, 'gauge seen as only collector')
    t.assert_equals(obs.value, -2, '3 - 5 = -2 (via metrics.collectors())')

    t.assert_equals(gauge:collect()[1].value, -2, '3 - 5 = -2')

    gauge:set(-8)

    t.assert_equals(gauge:collect()[1].value, -8, 'after set(-8) = -8')

    gauge:inc(-1)
    gauge:dec(-2)

    t.assert_equals(gauge:collect()[1].value, -7, '-8 + (-1) - (-2)')
end

g.test_histogram = function()
    t.assert_error_msg_contains("bad argument #1 to histogram (string expected, got nil)", function()
        metrics.histogram()
    end)

    t.assert_error_msg_contains("bad argument #1 to histogram (string expected, got number)", function()
        metrics.histogram(2)
    end)

    local h = metrics.histogram('hist', 'some histogram', {2, 4})

    h:observe(3)
    h:observe(5)

    local collectors = metrics.collectors()
    t.assert_equals(len(collectors), 1, 'histogram seen as only 1 collector')
    local observations = metrics.collect()
    local obs_sum = utils.find_obs('hist_sum', {}, observations)
    local obs_count = utils.find_obs('hist_count', {}, observations)
    local obs_bucket_2 = utils.find_obs('hist_bucket', { le = 2 }, observations)
    local obs_bucket_4 = utils.find_obs('hist_bucket', { le = 4 }, observations)
    local obs_bucket_inf = utils.find_obs('hist_bucket', { le = metrics.INF }, observations)
    t.assert_equals(#observations, 5, '<name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    t.assert_equals(obs_sum.value, 8, '3 + 5 = 8')
    t.assert_equals(obs_count.value, 2, '2 observed values')
    t.assert_equals(obs_bucket_2.value, 0, 'bucket 2 has no values')
    t.assert_equals(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    t.assert_equals(obs_bucket_inf.value, 2, 'bucket +inf has 2 values: 3, 5')

    h:observe(3, { foo = 'bar' })

    collectors = metrics.collectors()
    t.assert_equals(len(collectors), 1, 'still histogram seen as only 1 collector')
    observations = metrics.collect()
    obs_sum = utils.find_obs('hist_sum', { foo = 'bar' }, observations)
    obs_count = utils.find_obs('hist_count', { foo = 'bar' }, observations)
    obs_bucket_2 = utils.find_obs('hist_bucket', { le = 2, foo = 'bar' }, observations)
    obs_bucket_4 = utils.find_obs('hist_bucket', { le = 4, foo = 'bar' }, observations)
    obs_bucket_inf = utils.find_obs('hist_bucket', { le = metrics.INF, foo = 'bar' }, observations)

    t.assert_equals(#observations, 10, '+ <name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    t.assert_equals(obs_sum.value, 3, '3 = 3')
    t.assert_equals(obs_count.value, 1, '1 observed values')
    t.assert_equals(obs_bucket_2.value, 0, 'bucket 2 has no values')
    t.assert_equals(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    t.assert_equals(obs_bucket_inf.value, 1, 'bucket +inf has 1 value: 3')
end

g.test_counter_cache = function()
    local counter_1 = metrics.counter('cnt', 'test counter')
    local counter_2 = metrics.counter('cnt', 'test counter')
    local counter_3 = metrics.counter('cnt2', 'another test counter')

    counter_1:inc(3)
    counter_2:inc(5)
    counter_3:inc(7)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('cnt', {}, observations)
    t.assert_equals(len(collectors), 2, 'counter_1 and counter_2 refer to the same object')
    t.assert_equals(obs.value, 8, '3 + 5 = 8')
    obs = utils.find_obs('cnt2', {}, observations)
    t.assert_equals(obs.value, 7, 'counter_3 is the only reference to cnt2')
end

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

g.test_counter_remove_metric_by_label = function()
    local c = metrics.counter('cnt')

    c:inc(1, {label = 1})
    c:inc(1, {label = 2})

    utils.assert_observations(c:collect(), {
        {'cnt', 1, {label = 1}},
        {'cnt', 1, {label = 2}},
    })

    c:remove({label = 1})
    utils.assert_observations(c:collect(), {
        {'cnt', 1, {label = 2}},
    })
end

g.test_gauge_remove_metric_by_label = function()
    local c = metrics.gauge('gauge')

    c:set(1, {label = 1})
    c:set(1, {label = 2})

    utils.assert_observations(c:collect(), {
        {'gauge', 1, {label = 1}},
        {'gauge', 1, {label = 2}},
    })

    c:remove({label = 1})
    utils.assert_observations(c:collect(), {
        {'gauge', 1, {label = 2}},
    })
end

g.test_collector_reset = function()
    local c = metrics.counter('cnt', 'some counter')
    c:inc()
    t.assert_equals(c:collect()[1].value, 1)
    c:reset()
    t.assert_equals(c:collect()[1].value, 0)
end

g.test_default_metrics_clear = function()
    metrics.clear()
    metrics.enable_default_metrics()
    t.assert_equals(#metrics.collect(), 0)

    metrics.invoke_callbacks()
    t.assert(#metrics.collect() > 0)

    metrics.clear()
    t.assert_equals(#metrics.collect(), 0)

    metrics.enable_default_metrics()
    metrics.invoke_callbacks()
    t.assert(#metrics.collect() > 0)
end
