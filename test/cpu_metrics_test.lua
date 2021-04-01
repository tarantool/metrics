#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('cpu_metric')
local cpu = require('metrics.default_metrics.tarantool.cpu')
local utils = require('test.utils')

local metrics = require('metrics')

g.before_all(function()
    box.cfg{}
    metrics.clear()
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_cpu = function()
    metrics.clear()
    metrics.enable_default_metrics()
    cpu.update()
    local default_metrics = metrics.collect()
    local user_time_metric = utils.find_metric('tnt_cpu_user_time', default_metrics)
    local system_time_metric = utils.find_metric('tnt_cpu_system_time', default_metrics)
    t.assert(user_time_metric)
    t.assert(system_time_metric)
    t.assert(user_time_metric[1].value > 0)
    t.assert(system_time_metric[1].value > 0)
end
