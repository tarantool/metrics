#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('flight_recorder_plugin')

local flight_recorder_exporter = require('metrics.plugins.flight_recorder')
local metrics = require('metrics')
local metrics_stash = require('metrics.stash')
local utils = require('test.utils')

g.before_all(utils.init)

g.before_each(function()
    metrics_stash.get('flight_recorder').output_with_aggregates_prev = nil
    metrics.clear()
    metrics.cfg{include = 'all', exclude = {}, labels = {}}
end)

g.test_exporter = function()
    metrics.counter('counter_test_total'):inc(1)
    metrics.gauge('gauge_test'):set(1)
    metrics.histogram('histogram_test'):observe(1)
    metrics.summary('summary_test'):observe(1)

    local output_non_plugin = metrics.collect{invoke_callbacks = true, extended_format = true}

    local output_exporter_1 = flight_recorder_exporter.export()
    local output_exporter_2 = flight_recorder_exporter.export()
    local output_exporter_3 = flight_recorder_exporter.export()

    for key, _ in pairs(output_non_plugin) do
        t.assert_type(output_exporter_1[key], 'table',
            'Default metric observation presents in exporter output')
    end

    t.assert_gt(utils.len(output_exporter_1), utils.len(output_non_plugin),
        'Exporter observations is extended with aggregates (min, max, average)')

    t.assert_type(output_exporter_1['gauge_test_mingauge'], 'table',
        'Exporter observations is extended with min aggregates')
    t.assert_type(output_exporter_1['gauge_test_maxgauge'], 'table',
        'Exporter observations is extended with max aggregates')
    t.assert_type(output_exporter_1['histogram_test_averagegauge'], 'table',
        'Exporter observations is extended with histogram average aggregates')
    t.assert_type(output_exporter_1['summary_test_averagegauge'], 'table',
        'Exporter observations is extended with summary average aggregates')

    t.assert_gt(utils.len(output_exporter_2), utils.len(output_exporter_1),
        'Exporter observations is extended with aggregates (rate)')

    t.assert_type(output_exporter_2['counter_test_per_secondgauge'], 'table',
        'Exporter observations is extended with rate aggregates')

    t.assert_equals(utils.len(output_exporter_3), utils.len(output_exporter_2),
        'Exporter observations contains the same set of aggregates after second collect')
end

g.test_plain_format = function()
    metrics.cfg{labels = {alias = 'router-4'}}

    metrics.counter('counter_test_total'):inc(1, {label = 'value'})
    metrics.gauge('gauge_test'):set(2, {label = 'value'})
    metrics.histogram('histogram_test'):observe(3, {label = 'value'})
    metrics.summary('summary_test'):observe(4, {label = 'value'})

    local output = flight_recorder_exporter.export()

    local plain_format_output = flight_recorder_exporter.plain_format(output)
    t.assert_str_contains(plain_format_output,
        'counter_test_total{alias=router-4,label=value} 1')
    t.assert_str_contains(plain_format_output,
        'gauge_test{alias=router-4,label=value} 2')
    t.assert_str_contains(plain_format_output,
        'histogram_test_count{alias=router-4,label=value} 1')
    t.assert_str_contains(plain_format_output,
        'histogram_test_sum{alias=router-4,label=value} 3')
    t.assert_str_contains(plain_format_output,
        'summary_test_count{alias=router-4,label=value} 1')
    t.assert_str_contains(plain_format_output,
        'summary_test_sum{alias=router-4,label=value} 4')
end
