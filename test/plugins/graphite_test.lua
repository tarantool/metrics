#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local fiber = require('fiber')
local fun = require('fun')
local socket = require('socket')
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

g.before_each(function()
    metrics.clear()
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
    fun.iter(fiber.info()):
        filter(function(_, x) return x.name == 'metrics_graphite_worker' end):
        each(function(x) fiber.kill(x) end)
end)

g.test_graphite_format_observation_removes_ULL_suffix = function()
    local gauge = metrics.gauge('test_gauge', 'Test gauge')
    gauge:set(1ULL)
    local obs = gauge:collect()[1]
    local ull_number = tostring(obs.value)
    t.assert_equals(ull_number, '1ULL')

    local graphite_obs = graphite.format_observation('', obs)

    local graphite_val = graphite_obs:split(' ')[2]
    t.assert_equals(graphite_val, '1')
end

g.test_graphite_format_observation_removes_LL_suffix = function()
    local gauge = metrics.gauge('test_gauge', 'Test gauge')
    gauge:set(1LL)
    local obs = gauge:collect()[1]
    local ll_number = tostring(obs.value)
    t.assert_equals(ll_number, '1LL')

    local graphite_obs = graphite.format_observation('', obs)

    local graphite_val = graphite_obs:split(' ')[2]
    t.assert_equals(graphite_val, '1')
end

g.test_graphite_format_observation_time_in_seconds = function()
    local obs = {
        metric_name = 'test_metric',
        label_pairs = {},
        value = 1,
        timestamp = fiber.time64(),
    }

    local graphite_obs = graphite.format_observation('', obs)

    local graphite_time = tonumber(graphite_obs:split(' ')[3])
    local sec = obs.timestamp / 10^6
    t.assert_equals(graphite_time, sec)
end

g.test_graphite_sends_data_to_socket = function()
    local cnt = metrics.counter('test_cnt', 'test-cnt')
    cnt:inc(1)
    local port = 22003
    local sock = socket('AF_INET', 'SOCK_DGRAM', 'udp')
    sock:bind('127.0.0.1', port)

    graphite.init({port = port})

    fiber.sleep(0.5)
    local graphite_obs = sock:recvfrom(50)
    local obs_table = graphite_obs:split(' ')
    t.assert_equals(obs_table[1], 'tarantool.test_cnt')
    t.assert_equals(obs_table[2], '1')
    sock:close()
end

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
    fiber.sleep(0.5) -- wait to kill previous fibers
    local workers_cnt = count_workers()
    t.assert_equals(workers_cnt, 2)

    graphite.init({})

    fiber.sleep(0.5) -- wait to kill previous fibers
    workers_cnt = count_workers()
    t.assert_equals(workers_cnt, 1)
end
