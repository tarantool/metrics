#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('prometheus_plugin')

local metrics = require('metrics')

g.before_all(function()
    box.cfg{}
    box.schema.user.grant(
        'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
    )
    local s = box.schema.space.create(
        'random_space_for_prometheus',
        {if_not_exists = true})
    s:create_index('pk', {if_not_exists = true})

    -- Delete all previous collectors and global labels
    metrics.clear()
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

-- Enable default metrics collections
metrics.enable_default_metrics();

local http_handler = require('metrics.plugins.prometheus').collect_http

g.test_ll_ull_postfixes = function()
    local resp = http_handler().body

    t.assert_not(resp:match("ULL") ~= nil or resp:match("LL") ~= nil,
                  "Plugin output contains cdata postfixes")
end
