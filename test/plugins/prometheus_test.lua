#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group('prometheus_plugin')

local metrics = require('metrics')
local prometheus = require('metrics.plugins.prometheus')
local utils = require('test.utils')

g.before_all(function()
    utils.init()
    local s = box.schema.space.create(
        'random_space_for_prometheus',
        {if_not_exists = true})
    s:create_index('pk', {if_not_exists = true})

    local s_vinyl = box.schema.space.create(
        'random_vinyl_space_for_prometheus',
        {if_not_exists = true, engine = 'vinyl'})
    s_vinyl:create_index('pk', {if_not_exists = true})

    -- Enable default metrics collections
    metrics.enable_default_metrics()

    g.prometheus_metrics = prometheus.collect_http().body
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_ll_ull_postfixes = function()
    local resp = g.prometheus_metrics
    t.assert_not(resp:match("ULL") ~= nil or resp:match("LL") ~= nil,
                  "Plugin output contains cdata postfixes")
end

g.test_cdata_handling = function()
    t.assert_str_contains(g.prometheus_metrics, 'tnt_space_bsize{name="random_space_for_prometheus",engine="memtx"} 0',
        'Plugin output serialize 0ULL as +Inf')
end

g.test_collect_and_serialize_preserves_format = function()
    -- Prepare some data for all collector types.
    metrics.cfg{include = 'all', exclude = {}, labels = {alias = 'router-3'}}

    local c = metrics.counter('cnt', nil, {my_useful_info = 'here'})
    c:inc(3, {mylabel = 'myvalue1'})
    c:inc(2, {mylabel = 'myvalue2'})

    c = metrics.gauge('gauge', nil, {my_useful_info = 'here'})
    c:set(3, {mylabel = 'myvalue1'})
    c:set(2, {mylabel = 'myvalue2'})

    c = metrics.histogram('histogram', nil, {2, 4}, {my_useful_info = 'here'})
    c:observe(3, {mylabel = 'myvalue1'})
    c:observe(2, {mylabel = 'myvalue2'})

    local output_v1 = prometheus.internal.collect_and_serialize_v1()
    local output_v2 = prometheus.internal.collect_and_serialize_v2()

    for line in output_v1:gmatch('[^\r\n]+') do
        if line:startswith('#') then
            t.assert_str_contains(output_v2, line)
        else
            local _, _, value_line_header = line:find('^(.*)%s')
            -- Values of default metrics will be different for two different observations.
            t.assert_str_contains(output_v2, value_line_header)
        end
    end
end
