#!/usr/bin/env tarantool

require('strict').on()

local t = require('luatest')
local g = t.group('luajit_metrics')
local utils = require('test.utils')

g.before_all(function(cg)
    t.skip_if(jit.os ~= 'Linux', 'Linux is the only supported platform')
    utils.create_server(cg)
end)

g.after_all(utils.drop_server)

g.after_each(function(cg)
    cg.server:exec(function()
        require('metrics').clear()
    end)
end)

g.test_lj_metrics = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')

        local metrics_available = pcall(require, 'misc')
        t.skip_if(metrics_available == false, 'metrics are not available')

        metrics.enable_default_metrics()

        local lj_metrics = {}
        for _, v in pairs(metrics.collect{invoke_callbacks = true}) do
            if v.metric_name:startswith('lj_') then
                table.insert(lj_metrics, v.metric_name)
            end
        end
        table.sort(lj_metrics)

        local expected_lj_metrics = {
            "lj_gc_freed_total",
            "lj_strhash_hit_total",
            "lj_gc_steps_atomic_total",
            "lj_strhash_miss_total",
            "lj_gc_steps_sweepstring_total",
            "lj_gc_strnum",
            "lj_gc_tabnum",
            "lj_gc_cdatanum",
            "lj_jit_snap_restore_total",
            "lj_gc_memory",
            "lj_gc_udatanum",
            "lj_gc_steps_finalize_total",
            "lj_gc_allocated_total",
            "lj_jit_trace_num",
            "lj_gc_steps_sweep_total",
            "lj_jit_trace_abort_total",
            "lj_jit_mcode_size",
            "lj_gc_steps_propagate_total",
            "lj_gc_steps_pause_total",
        }
        table.sort(expected_lj_metrics)

        t.assert_equals(#lj_metrics, #expected_lj_metrics)
        t.assert_items_equals(lj_metrics, expected_lj_metrics)
    end)
end
