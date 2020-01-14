#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('json_plugin')

local json_exporter = require('metrics.plugins.json')
local metrics = require('metrics')
local json = require('json')
local utils = require('test.utils')

g.before_all(function()
    box.cfg{}
    box.schema.user.grant(
        'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
    )

    -- Delete all previous collectors and global labels
    metrics.clear()
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_infinite_value_serialization = function()
    local test_nan = metrics.gauge('test_nan')
    local test_inf = metrics.gauge('test_inf')

    test_nan:set( metrics.NAN, { type =  metrics.NAN } )
    test_inf:set( metrics.INF, { type =  metrics.INF } )
    test_inf:set(-metrics.INF, { type = -metrics.INF } )

    local json_metrics = json.decode(json_exporter.export())

    local nan_obs = utils.find_obs(
       'test_nan', { type =  tostring(metrics.NAN) }, json_metrics)
    t.assert_equals(nan_obs.value,     tostring( metrics.NAN ), 'check  NaN')

    local inf_pos_obs = utils.find_obs(
       'test_inf', { type =  tostring(metrics.INF) }, json_metrics)
    t.assert_equals(inf_pos_obs.value, tostring( metrics.INF ), 'check  INF')

    local inf_neg_obs = utils.find_obs(
       'test_inf', { type =  tostring(-metrics.INF) }, json_metrics)
    t.assert_equals(inf_neg_obs.value, tostring(-metrics.INF ), 'check -INF')
end

g.test_number_value_serialization = function()
    local test_num_float = metrics.gauge('number_float')
    local test_num_int = metrics.counter('number_int')

    test_num_float:set(0.333, { type = 'float', nan = metrics.NAN })
    test_num_int:inc(10, { type = 'int', inf = metrics.INF })

    local json_metrics = json.decode(json_exporter.export())

    local float_obs = utils.find_obs(
        'number_float',
        { type = 'float', nan = tostring(metrics.NAN) }, json_metrics)

    local int_obs = utils.find_obs(
        'number_int',
        { type = 'int', inf = tostring(metrics.INF) }, json_metrics)

    t.assert_equals(float_obs.value, 0.333, 'check float')
    t.assert_equals(int_obs.value, 10, 'check int')
end

g.test_histogram = function()
    local h = metrics.histogram('hist', 'some histogram', {2, 4})

    h:observe(3)
    h:observe(5)

    local observations = json.decode(json_exporter.export())

    local obs_sum = utils.find_obs('hist_sum', {}, observations)
    local obs_count = utils.find_obs('hist_count', {}, observations)
    local obs_bucket_2 = utils.find_obs('hist_bucket', { le = 2 }, observations)
    local obs_bucket_4 = utils.find_obs('hist_bucket', { le = 4 }, observations)
    local obs_bucket_inf = utils.find_obs('hist_bucket', { le = tostring(metrics.INF) }, observations)
    t.assert_equals(#observations, 5, '<name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    t.assert_equals(obs_sum.value, 8, '3 + 5 = 8')
    t.assert_equals(obs_count.value, 2, '2 observed values')
    t.assert_equals(obs_bucket_2.value, 0, 'bucket 2 has no values')
    t.assert_equals(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    t.assert_equals(obs_bucket_inf.value, 2, 'bucket +inf has 2 values: 3, 5')
end
