#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('json_plugin')

local json_exporter = require('metrics.plugins.json')
local metrics = require('metrics')
local json = require('json')
local utils = require('test.utils')

g.before_all(utils.init)

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

g.test_number64_ll_value_parses_to_json_number = function()
    local gauge_ll = metrics.gauge('test_cdata_ll')
    gauge_ll:set(-9007199254740992LL)

    local json_metrics = json.decode(json_exporter.export())
    local obs_ll = utils.find_obs('test_cdata_ll', {}, json_metrics)
    t.assert_not_equals(type(obs_ll.value), 'string', 'number64 is not casted to string on export')
    t.assert_equals(obs_ll.value, -9007199254740992LL, 'number64 LL parsed to corrent number value')
end

g.test_number64_ull_value_parses_to_json_number = function()
    local gauge_ull = metrics.gauge('test_cdata_ull')
    gauge_ull:set(9007199254740992ULL)

    local json_metrics = json.decode(json_exporter.export())
    local obs_ull = utils.find_obs('test_cdata_ull', {}, json_metrics)
    t.assert_not_equals(type(obs_ull.value), 'string', 'number64 is not casted to string on export')
    t.assert_equals(obs_ull.value, 9007199254740992ULL, 'number64 ULL parsed to corrent number value')
end
