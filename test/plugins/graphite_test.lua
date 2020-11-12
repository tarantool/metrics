#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local fiber = require('fiber')
local fun = require('fun')
local graphite = require('metrics.plugins.graphite')

g.before_all(function()
    box.cfg{}
    box.schema.user.grant(
        'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
    )
    local s = box.schema.space.create(
        'random_space_for_graphite',
        {if_not_exists = true})
    s:create_index('pk', {if_not_exists = true})

    local s_vinyl = box.schema.space.create(
        'random_vinyl_space_for_graphite',
        {if_not_exists = true, engine = 'vinyl'})
    s_vinyl:create_index('pk', {if_not_exists = true})

    -- Delete all previous collectors and global labels
    metrics.clear()

    -- Enable default metrics collections
    metrics.enable_default_metrics();
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

local function mock_graphite_worker()
    fiber.create(function()
        fiber.name('metrics_graphite_worker')
        while true do fiber.sleep(0.01) end
    end)
end

local function count_workers()
    return fun.iter(fiber.info()):
        filter(function(_, x) return x.name == 'metrics_graphite_worker' end):
        length()
end

g.test_graphite_kills_previous_fibers_on_init = function()
    mock_graphite_worker()
    mock_graphite_worker()
    local workers_cnt = count_workers()
    t.assert_equals(workers_cnt, 2)

    graphite.init({})

    fiber.sleep(0.5)
    workers_cnt = count_workers()
    t.assert_equals(workers_cnt, 1)
end

