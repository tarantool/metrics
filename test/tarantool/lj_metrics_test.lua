#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group('luajit_metrics')

local metrics = require('metrics')

local LJ_PREFIX = 'lj_'

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_lj_metrics = function()
    local metrics_available = pcall(require, 'misc')
    t.skip_if(metrics_available == false, 'metrics are not available')

    metrics.enable_default_metrics()
    metrics.invoke_callbacks()

    local lj_metrics = {}
    for _, v in pairs(metrics.collect()) do
        if v.metric_name:startswith(LJ_PREFIX) then
            table.insert(lj_metrics, v.metric_name)
        end
    end

    local expected_lj_metrics = {
        "lj_gc_freed",
        "lj_strhash_hit",
        "lj_gc_steps_atomic",
        "lj_strhash_miss",
        "lj_gc_steps_sweepstring",
        "lj_gc_strnum",
        "lj_gc_tabnum",
        "lj_gc_cdatanum",
        "lj_jit_snap_restore",
        "lj_gc_total",
        "lj_gc_memory",
        "lj_gc_udatanum",
        "lj_gc_steps_finalize",
        "lj_gc_allocated",
        "lj_jit_trace_num",
        "lj_gc_steps_sweep",
        "lj_jit_trace_abort",
        "lj_jit_mcode_size",
        "lj_gc_steps_propagate",
        "lj_gc_steps_pause",
    }

    t.assert_items_equals(lj_metrics, expected_lj_metrics)
end
