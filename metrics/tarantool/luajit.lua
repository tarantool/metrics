local metrics = require('metrics')

local Shared = require('metrics.collectors.shared')

local has_mics_module, misc = pcall(require, 'misc')

local LJ_PREFIX = 'lj_'

local function prefix_name(name)
    return LJ_PREFIX .. name
end

local function set_gauge(name, description, value, labels)
    local gauge = metrics.gauge(prefix_name(name), description)
    gauge:set(value, labels or {})
    return gauge
end

local function set_counter(name, description, value, labels)
    local counter = metrics.counter(prefix_name(name), description)
    if counter.set == nil then
        counter.set = Shared.set
    end
    counter:set(value, labels or {})
    return counter
end

local collectors_list = {}

local function update()
    if not (has_mics_module and misc.getmetrics ~= nil) then
        return
    end
    -- Details: https://github.com/tarantool/doc/issues/1597
    local lj_metrics = misc.getmetrics()
    collectors_list.gc_freed =
        set_counter('gc_freed', 'Total amount of freed memory', lj_metrics.gc_freed)
    collectors_list.strhash_hit =
        set_counter('strhash_hit', 'Number of strings being interned', lj_metrics.strhash_hit)
    collectors_list.gc_steps_atomic =
        set_counter('gc_steps_atomic', 'Count of incremental GC steps (atomic state)', lj_metrics.gc_steps_atomic)
    collectors_list.strhash_miss =
        set_counter('strhash_miss', 'Total number of strings allocations during the platform lifetime',
            lj_metrics.strhash_miss)
    collectors_list.gc_steps_sweepstring =
        set_counter('gc_steps_sweepstring', 'Count of incremental GC steps (sweepstring state)',
            lj_metrics.gc_steps_sweepstring)
    collectors_list.gc_strnum =
        set_gauge('gc_strnum', 'Amount of allocated string objects', lj_metrics.gc_strnum)
    collectors_list.gc_tabnum =
        set_gauge('gc_tabnum', 'Amount of allocated table objects', lj_metrics.gc_tabnum)
    collectors_list.gc_cdatanum =
        set_gauge('gc_cdatanum', 'Amount of allocated cdata objects', lj_metrics.gc_cdatanum)
    collectors_list.jit_snap_restore =
        set_counter('jit_snap_restore', 'Overall number of snap restores', lj_metrics.jit_snap_restore)
    collectors_list.gc_total =
        set_gauge('gc_total', 'Memory currently allocated', lj_metrics.gc_total)
    collectors_list.gc_udatanum =
        set_gauge('gc_udatanum', 'Amount of allocated udata objects', lj_metrics.gc_udatanum)
    collectors_list.gc_steps_finalize =
        set_counter('gc_steps_finalize', 'Count of incremental GC steps (finalize state)', lj_metrics.gc_steps_finalize)
    collectors_list.gc_allocated =
        set_counter('gc_allocated', 'Total amount of allocated memory', lj_metrics.gc_allocated)
    collectors_list.jit_trace_num =
        set_gauge('jit_trace_num', 'Amount of JIT traces', lj_metrics.jit_trace_num)
    collectors_list.gc_steps_sweep =
        set_counter('gc_steps_sweep', 'Count of incremental GC steps (sweep state)', lj_metrics.gc_steps_sweep)
    collectors_list.jit_trace_abort =
        set_counter('jit_trace_abort', 'Overall number of abort traces', lj_metrics.jit_trace_abort)
    collectors_list.jit_mcode_size =
        set_gauge('jit_mcode_size', 'Total size of all allocated machine code areas', lj_metrics.jit_mcode_size)
    collectors_list.gc_steps_propagate =
        set_counter('gc_steps_propagate', 'Count of incremental GC steps (propagate state)',
            lj_metrics.gc_steps_propagate)
    collectors_list.gc_steps_pause =
        set_counter('gc_steps_pause', 'Count of incremental GC steps (pause state)', lj_metrics.gc_steps_pause)
end

return {
    update = update,
    list = collectors_list,
}
