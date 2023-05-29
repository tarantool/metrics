#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group('prometheus_plugin')

local utils = require('test.utils')

g.before_all(function(cg)
    utils.create_server(cg)
    cg.prometheus_metrics = cg.server:exec(function()
        local s = box.schema.space.create(
            'random_space_for_prometheus',
            {if_not_exists = true})
        s:create_index('pk', {if_not_exists = true})

        local s_vinyl = box.schema.space.create(
            'random_vinyl_space_for_prometheus',
            {if_not_exists = true, engine = 'vinyl'})
        s_vinyl:create_index('pk', {if_not_exists = true})

        -- Enable default metrics collections
        require('metrics').enable_default_metrics()

        return require('metrics.plugins.prometheus').collect_http().body
    end)
end)

g.after_all(utils.drop_server)

g.test_ll_ull_postfixes = function()
    local resp = g.prometheus_metrics
    t.assert_not(resp:match("ULL") ~= nil or resp:match("LL") ~= nil,
                  "Plugin output contains cdata postfixes")
end

g.test_cdata_handling = function()
    t.assert_str_contains(g.prometheus_metrics, 'tnt_space_bsize{name="random_space_for_prometheus",engine="memtx"} 0',
        'Plugin output serialize 0ULL as +Inf')
end
