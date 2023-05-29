require('strict').on()

local t = require('luatest')
local g = t.group('hotreload')

local utils = require('test.utils')

g.before_all(function(cg)
    utils.create_server(cg)
    cg.server:exec(function()
        local function package_reload()
            for k, _ in pairs(package.loaded) do
                if k:find('metrics') ~= nil then
                    package.loaded[k] = nil
                end
            end

            return require('metrics')
        end

        rawset(_G, 'package_reload', package_reload)
    end)
end)

g.after_all(utils.drop_server)

g.test_reload = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')

        local http_requests_total_counter = metrics.counter('http_requests_total')
        http_requests_total_counter:inc(1, {method = 'GET'})

        local http_requests_latency = metrics.summary(
            'http_requests_latency', 'HTTP requests total',
            {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}
        )
        http_requests_latency:observe(10)

        metrics.enable_default_metrics()

        metrics = rawget(_G, 'package_reload')()

        metrics.enable_default_metrics()
    end)
end

g.test_cartridge_hotreload_preserves_cfg_state = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local utils = require('test.utils') -- luacheck: ignore 431

        local cfg_before_hotreload = metrics.cfg{include = {'operations'}}
        local obs_before_hotreload = metrics.collect{invoke_callbacks = true}

        metrics = rawget(_G, 'package_reload')()

        local cfg_after_hotreload = metrics.cfg
        box.space._space:select(nil, {limit = 1})
        local obs_after_hotreload = metrics.collect{invoke_callbacks = true}

        t.assert_equals(cfg_before_hotreload, cfg_after_hotreload,
            "cfg values are preserved")

        local op_before = utils.find_obs('tnt_stats_op_total', {operation = 'select'},
            obs_before_hotreload, t.assert_covers)
        local op_after = utils.find_obs('tnt_stats_op_total', {operation = 'select'},
            obs_after_hotreload, t.assert_covers)
        t.assert_gt(op_after.value, op_before.value, "metric callbacks enabled by cfg stay enabled")
    end)
end
