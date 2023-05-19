require('strict').on()

local fio = require('fio')

local t = require('luatest')
local g = t.group('hotreload')

local utils = require('test.utils')

local function package_reload()
    for k, _ in pairs(package.loaded) do
        if k:find('metrics') ~= nil then
            package.loaded[k] = nil
        end
    end

    return require('metrics')
end

g.test_reload = function()
    local tmpdir = fio.tempdir()
    if type(box.cfg) == 'function' then
        box.cfg {
            wal_dir = tmpdir,
            memtx_dir = tmpdir,
        }
    end

    local metrics = require('metrics')

    local http_requests_total_counter = metrics.counter('http_requests_total')
    http_requests_total_counter:inc(1, {method = 'GET'})

    local http_requests_latency = metrics.summary(
        'http_requests_latency', 'HTTP requests total',
        {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}
    )
    http_requests_latency:observe(10)

    metrics.enable_default_metrics()

    metrics = package_reload()

    metrics.enable_default_metrics()
end

g.test_cartridge_hotreload_preserves_cfg_state = function()
    local metrics = require('metrics')

    local cfg_before_hotreload = metrics.cfg{include = {'operations'}}
    local obs_before_hotreload = metrics.collect{invoke_callbacks = true}

    metrics = package_reload()

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
end
