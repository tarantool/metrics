#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('cpu_metric')
local utils = require('test.utils')

g.before_all(utils.create_server)

g.after_all(utils.drop_server)

g.before_each(function(cg)
    cg.server:exec(function() require('metrics').clear() end)
end)

g.test_cpu = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local cpu = require('metrics.tarantool.cpu')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.enable_default_metrics()
        cpu.update()
        local default_metrics = metrics.collect()
        local user_time_metric = utils.find_metric('tnt_cpu_user_time', default_metrics)
        local system_time_metric = utils.find_metric('tnt_cpu_system_time', default_metrics)
        t.assert(user_time_metric)
        t.assert(system_time_metric)
        t.assert(user_time_metric[1].value > 0)
        t.assert(system_time_metric[1].value > 0)
    end)
end
