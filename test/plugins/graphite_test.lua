#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group()

local socket = require('socket')
local utils = require('test.utils')

g.before_all(function(cg)
    utils.create_server(cg)
    cg.server:exec(function()
        local metrics = require('metrics')

        local s = box.schema.space.create(
            'random_space_for_graphite',
            {if_not_exists = true})
        s:create_index('pk', {if_not_exists = true})

        local s_vinyl = box.schema.space.create(
            'random_vinyl_space_for_graphite',
            {if_not_exists = true, engine = 'vinyl'})
        s_vinyl:create_index('pk', {if_not_exists = true})

        -- Enable default metrics collections
        metrics.enable_default_metrics()
    end)
end)

g.after_all(utils.drop_server)

g.before_each(function(cg)
    cg.server:exec(function() require('metrics').clear() end)
end)

g.after_each(function(cg)
    cg.server:exec(function()
        local fiber = require('fiber')
        local fun = require('fun')
        local metrics = require('metrics')
        -- Delete all collectors and global labels
        metrics.clear()
        fun.iter(fiber.info()):
            filter(function(_, x) return x.name == 'metrics_graphite_worker' end):
            each(function(x) fiber.kill(x) end)
        fiber.yield() -- let cancelled fibers disappear from fiber.info()
    end)
end)

g.test_graphite_format_observation_removes_ULL_suffix = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local graphite = require('metrics.plugins.graphite')

        local gauge = metrics.gauge('test_gauge', 'Test gauge')
        gauge:set(1ULL)
        local obs = gauge:collect()[1]
        local ull_number = tostring(obs.value)
        t.assert_equals(ull_number, '1ULL')

        local graphite_obs = graphite.format_observation('', obs)

        local graphite_val = graphite_obs:split(' ')[2]
        t.assert_equals(graphite_val, '1')
    end)
end

g.test_graphite_format_observation_removes_LL_suffix = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local graphite = require('metrics.plugins.graphite')

        local gauge = metrics.gauge('test_gauge', 'Test gauge')
        gauge:set(1LL)
        local obs = gauge:collect()[1]
        local ll_number = tostring(obs.value)
        t.assert_equals(ll_number, '1LL')

        local graphite_obs = graphite.format_observation('', obs)

        local graphite_val = graphite_obs:split(' ')[2]
        t.assert_equals(graphite_val, '1')
    end)
end

g.test_graphite_format_observation_float = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local graphite = require('metrics.plugins.graphite')

        local gauge = metrics.gauge('test_gauge', 'Test gauge')
        gauge:set(1.5)
        local obs = gauge:collect()[1]
        local ll_number = tostring(obs.value)
        t.assert_equals(ll_number, '1.5')

        local graphite_obs = graphite.format_observation('', obs)

        local graphite_val = graphite_obs:split(' ')[2]
        t.assert_equals(graphite_val, '1.5')
    end)
end

g.test_graphite_format_observation_time_in_seconds = function(cg)
    cg.server:exec(function()
        local fiber = require('fiber')
        local graphite = require('metrics.plugins.graphite')

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
    end)
end

g.test_graphite_format_observation_signed_time = function(cg)
    cg.server:exec(function()
        local graphite = require('metrics.plugins.graphite')

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
    end)
end

g.test_graphite_sends_data_to_socket = function(cg)
    local port = 22003
    local sock = socket('AF_INET', 'SOCK_DGRAM', 'udp')
    sock:bind('127.0.0.1', port)

    cg.server:exec(function(port) -- luacheck: ignore 431
        local metrics = require('metrics')
        local graphite = require('metrics.plugins.graphite')

        local cnt = metrics.counter('test_cnt', 'test-cnt')
        cnt:inc(1)
        graphite.init({port = port})
    end, {port})

    require('fiber').sleep(0.5)
    local graphite_obs = sock:recvfrom(50)
    local obs_table = graphite_obs:split(' ')
    t.assert_equals(obs_table[1], 'tarantool.test_cnt')
    t.assert_equals(obs_table[2], '1')
    sock:close()
end

g.test_graphite_kills_previous_fibers_on_init = function(cg)
    cg.server:exec(function()
        local fiber = require('fiber')
        local fun = require('fun')
        local graphite = require('metrics.plugins.graphite')

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

        t.assert_equals(count_workers(), 0)
        mock_graphite_worker()
        mock_graphite_worker()
        t.assert_equals(count_workers(), 2)

        graphite.init({})
        fiber.yield() -- let cancelled fibers disappear from fiber.info()
        t.assert_equals(count_workers(), 1)
    end)
end
