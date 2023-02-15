#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local fiber = require('fiber')
local fun = require('fun')
local socket = require('socket')
local graphite = require('metrics.plugins.graphite')
local utils = require('test.utils')

g.before_all(function()
    utils.init()
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
    metrics.enable_default_metrics()
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
    fiber.yield() -- let cancelled fibers disappear from fiber.info()
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

g.test_graphite_format_observation_float = function()
    local gauge = metrics.gauge('test_gauge', 'Test gauge')
    gauge:set(1.5)
    local obs = gauge:collect()[1]
    local ll_number = tostring(obs.value)
    t.assert_equals(ll_number, '1.5')

    local graphite_obs = graphite.format_observation('', obs)

    local graphite_val = graphite_obs:split(' ')[2]
    t.assert_equals(graphite_val, '1.5')
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

g.test_graphite_format_observation_signed_time = function()
    local obs = {
        metric_name = 'test_metric',
        label_pairs = {},
        value = 1,
        timestamp = 1000000000000LL,
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
        fiber.sleep(math.huge)
    end)
end

local function count_workers()
    return fun.iter(fiber.info()):
        filter(function(_, x) return x.name == 'metrics_graphite_worker' end):
        length()
end

g.test_graphite_kills_previous_fibers_on_init = function()
    t.assert_equals(count_workers(), 0)
    mock_graphite_worker()
    mock_graphite_worker()
    t.assert_equals(count_workers(), 2)

    graphite.init({})
    fiber.yield() -- let cancelled fibers disappear from fiber.info()
    t.assert_equals(count_workers(), 1)
end

g.test_collect_and_push_preseves_format = function(group)
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

    local port_v1 = 22003
    group.sock_v1 = socket('AF_INET', 'SOCK_DGRAM', 'udp')
    group.sock_v1:bind('127.0.0.1', port_v1)
    local port_v2 = 22004
    group.sock_v2 = socket('AF_INET', 'SOCK_DGRAM', 'udp')
    group.sock_v2:bind('127.0.0.1', port_v2)

    graphite.internal.collect_and_push_v1({
        prefix = 'tarantool',
        host = '127.0.0.1',
        port = port_v1,
        sock = group.sock_v1,
    })
    graphite.internal.collect_and_push_v2({
        prefix = 'tarantool',
        host = '127.0.0.1',
        port = port_v2,
        sock = group.sock_v2,
    })

    local output_v2 = ''
    while true do
        local output_v2_part = group.sock_v2:recvfrom(200)
        if output_v2_part == nil or output_v2_part == '' then
            break
        end

        output_v2 = output_v2 .. ' ' .. output_v2_part
    end

    while true do
        local output_v1_part = group.sock_v1:recvfrom(200)
        if output_v1_part == nil or output_v1_part == '' then
            break
        end

        t.assert_str_contains(output_v2, output_v1_part:split(' ')[1])
    end
end

g.after_test('test_collect_and_push_preseves_format', function(group)
    if group.sock_v1 then
        group.sock_v1:close()
    end

    if group.sock_v2 then
        group.sock_v2:close()
    end
end)
