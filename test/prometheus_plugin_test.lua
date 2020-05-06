#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group('prometheus_plugin')

local metrics = require('metrics')
local http_handler = require('metrics.plugins.prometheus').collect_http

g.before_all(function()
    box.cfg{}
    box.schema.user.grant(
        'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
    )
    local s = box.schema.space.create(
        'random_space_for_prometheus',
        {if_not_exists = true})
    s:create_index('pk', {if_not_exists = true})

    local s_vinyl = box.schema.space.create(
        'random_vinyl_space_for_prometheus',
        {if_not_exists = true, engine = 'vinyl'})
    s_vinyl:create_index('pk', {if_not_exists = true})

    -- Delete all previous collectors and global labels
    metrics.clear()

    -- Enable default metrics collections
    metrics.enable_default_metrics();

    g.prometheus_metrics = http_handler().body
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
