#!/usr/bin/env tarantool

local json_metrics = require('metrics.plugin.json')
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
        test:plan(9)

        do
            test:diag('test NaN')

            metrics.clear()
            local test_nan = metrics.gauge('test_nan')
            test_nan:set( metrics.NAN, { type =  metrics.NAN } )
            local json_metrics = json.decode(json_exporter.export())

            test:is(
                json_metrics[1]['name'],
                'test_nan',
                'check  name')
            
            test:is(
                json_metrics[1]['type'],
                'nan',
                'check  type')

            test:is(
                json_metrics[1]['value'],
                'nan',
                'check  value')
        end

        do
            test:diag('test INF')

            metrics.clear()

            local test_inf = metrics.gauge('test_inf')
            test_inf:set( metrics.INF, { type =  metrics.INF })
            local json_metrics = json.decode(json_exporter.export())

            test:is(
                json_metrics[1]['name'],
                'test_inf',
                'check name')

            test:is(
                json_metrics[1]['type'],
                'inf',
                'check type')

            test:is(
                json_metrics[1]['value'],
                'inf',
                'check value')
        end

        do
            test:diag('test -INF')

            metrics.clear() 
            local test_inf = metrics.gauge('test_inf')

            test_inf:set(-metrics.INF, { type = -metrics.INF })

            local json_metrics = json.decode(json_exporter.export())
            
            test:is(
                json_metrics[1]['name'],
                'test_inf',
                'check name')

            test:is(
                json_metrics[1]['type'],
                '-inf',
                'check type')

            test:is(
                json_metrics[1]['value'],
                '-inf',
                'check value')
        end
    end)

test:test(
    'number value serialization',
    function(test)
        test:plan(3)
        test:diag('test NUM')
        metrics.clear()

        local test_num = metrics.gauge('test_num')

        test_num:set(0.333, { type = 'number', degree = -1 })
        local json_metrics = json.decode(json_exporter.export())

        test:is(
            json_metrics[1]['name'],
            'test_num',
            'check name')
        
        test:is(
            json_metrics[1]['type'],
            'number',
            'check type')

        test:is(
            json_metrics[1]['value'],
            0.333,
            'check value')
    end)
os.exit(test:check() and 0 or 1)