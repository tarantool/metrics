#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('prometheus_plugin')

local metrics = require('metrics')
local tap = require('tap')

g.before_all = function()
    box.cfg{}
    box.schema.user.grant(
        'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
    )
    local s = box.schema.space.create(
        'random_space_for_prometheus',
        {if_not_exists = true})
    s:create_index('pk', {if_not_exists = true})
end

-- Enable default metrics collections
metrics.enable_default_metrics();

local http_handler = require('metrics.plugins.prometheus').collect_http

g.test_ll_ull_postfixes = function()
    local resp = http_handler().body

    t.assertFalse(resp:match("ULL") ~= nil or resp:match("LL") ~= nil,
                  "Plugin output contains cdata postfixes")
end
