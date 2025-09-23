#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('instance_metric')
local utils = require('test.utils')

g.before_all(function(cg)
    utils.create_server(cg)
    cg.server:exec(function()
        box.cfg{}
        local space = box.schema.space.create(
            'test_space',
            {if_not_exists = true, engine = 'vinyl'})
        space:create_index('pk', {if_not_exists = true})
    end)
end)

g.after_all(utils.drop_server)

g.after_each(function(cg)
    cg.server:exec(function()
        require('metrics').clear()
    end)
end)

g.test_instance_metrics = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local memory = require('metrics.tarantool.memory')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.enable_default_metrics()
        memory.update()
        local default_metrics = metrics.collect{invoke_callbacks = true}

        local memory_metric = utils.find_metric('tnt_memory', default_metrics)
        t.assert(memory_metric)
        t.assert_gt(memory_metric[1].value, 0)

        local memory_virt_metric = utils.find_metric('tnt_memory_virt', default_metrics)
        t.assert(memory_virt_metric)
        t.assert_gt(memory_virt_metric[1].value, 0)
    end)
end
