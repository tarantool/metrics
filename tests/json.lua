#!/usr/bin/env tarantool

local json_exporter = require('metrics.plugin.json')
local metrics = require('metrics')
local json = require('json')
local tap = require('tap')
local utils = require 'utils'

-- initialize tarantool
box.cfg{}
box.schema.user.grant(
    'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
)

local test = tap.test('json_exporter')
test:plan(3)

test:test(
    'infinite value serialization',
    function(test)
        test:plan(3)
        metrics.clear()

        local test_nan = metrics.gauge('test_nan')
        local test_inf = metrics.gauge('test_inf')

        test_nan:set( metrics.NAN, { type =  metrics.NAN } )
        test_inf:set( metrics.INF, { type =  metrics.INF } )
        test_inf:set(-metrics.INF, { type = -metrics.INF } )

        local json_metrics = json.decode(json_exporter.export())

        local nan_obs = utils.find_obs(
            'test_nan', { type =  tostring(metrics.NAN) }, json_metrics)
        test:is(nan_obs.value,     tostring( metrics.NAN ), 'check  NaN')

        local inf_pos_obs = utils.find_obs(
            'test_inf', { type =  tostring(metrics.INF) }, json_metrics)
        test:is(inf_pos_obs.value, tostring( metrics.INF ), 'check  INF')

        local inf_neg_obs = utils.find_obs(
            'test_inf', { type =  tostring(-metrics.INF) }, json_metrics)
        test:is(inf_neg_obs.value, tostring(-metrics.INF ), 'check -INF')
    end)

test:test(
    'number value serialization',
    function(test)
        test:plan(2)
        metrics.clear()

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

        test:is(float_obs.value, 0.333, 'check float')
        test:is(int_obs.value, 10, 'check int')
        
    end)

test:test(
    'histogram',
    function(test)
        test:plan(6)
        metrics.clear()
        test:diag("create histogram with {2, 4} buckets")
        local h = metrics.histogram('hist', 'some histogram', {2, 4})

        test:diag("observe(3), observe(5)")
        h:observe(3)
        h:observe(5)
        
        local observations = json.decode(json_exporter.export())

        local obs_sum = utils.find_obs('hist_sum', {}, observations)
        local obs_count = utils.find_obs('hist_count', {}, observations)
        local obs_bucket_2 = utils.find_obs('hist_bucket', {le = 2}, observations)
        local obs_bucket_4 = utils.find_obs('hist_bucket', {le = 4}, observations)
        local obs_bucket_inf = utils.find_obs('hist_bucket', {le = tostring(metrics.INF)}, observations)
        test:is(#observations, 5, '<name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
        test:is(obs_sum.value, 8, '3 + 5 = 8')
        test:is(obs_count.value, 2, '2 observed values')
        test:is(obs_bucket_2.value, 0, 'bucket 2 has no values')
        test:is(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
        test:is(obs_bucket_inf.value, 2, 'bucket +inf has 2 values: 3, 5')
    end)
os.exit(test:check() and 0 or 1)