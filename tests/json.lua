#!/usr/bin/env tarantool

local json_exporter = require('metrics.plugin.json')
local metrics = require('metrics')
local json = require('json')
local tap = require('tap')

-- initialize tarantool
box.cfg{}
box.schema.user.grant(
    'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
)

local test = tap.test('json_exporter')
test:plan(2)

test:test(
    'infinite value serialization',
    function(test)
        test:plan(3)
        metrics.clear()

        local test_nan = metrics.gauge('test_nan')
        local test_inf = metrics.gauge('test_inf')

        test_nan:set( metrics.NAN, { type =  metrics.NAN })
        test_inf:set( metrics.INF, { type =  metrics.INF })
        test_inf:set(-metrics.INF, { type = -metrics.INF })

        local json_metrics = json.decode(json_exporter.collect())

        test:is(
            json_metrics['test_nan{type="nan"}'].value,
            'nan',
            'test  NaN')

        test:is(
            json_metrics['test_inf{type="inf"}'].value,
            'inf',
            'test  Inf')

        test:is(
            json_metrics['test_inf{type="-inf"}'].value,
            '-inf',
            'test -Inf')
    end)

test:test(
    'number value serialization',
    function(test)
        test:plan(1)
        metrics.clear()

        local test_num = metrics.gauge('test_num')

        test_num:set(0.333, { type = 'number', degree = -1 })
        local json_metrics = json.decode(json_exporter.collect())
        test:is(
            json_metrics['test_num{type="number",degree="-1"}'].value,
            0.333,
            'test 0.333')

    end)
os.exit(test:check() and 0 or 1)