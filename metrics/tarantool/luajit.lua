local has_mics_module, misc = pcall(require, 'misc')

local LJ_PREFIX = 'lj_'

local utils = require('metrics.utils')

local collectors_list = {}

local function update()
    if not (has_mics_module and misc.getmetrics ~= nil) then
        return
    end
    -- Details: https://github.com/tarantool/doc/issues/1597
    local lj_metrics = misc.getmetrics()
    collectors_list.gc_freed =
        utils.set_counter('gc_freed', 'Total amount of freed memory', lj_metrics.gc_freed, nil, LJ_PREFIX)
    collectors_list.strhash_hit =
        utils.set_counter('strhash_hit', 'Number of strings being interned', lj_metrics.strhash_hit, nil, LJ_PREFIX)
    collectors_list.gc_steps_atomic =
        utils.set_counter('gc_steps_atomic', 'Count of incremental GC steps (atomic state)',
            lj_metrics.gc_steps_atomic, nil, LJ_PREFIX)
    collectors_list.strhash_miss =
        utils.set_counter('strhash_miss', 'Total number of strings allocations during the platform lifetime',
            lj_metrics.strhash_miss, nil, LJ_PREFIX)
    collectors_list.gc_steps_sweepstring =
        utils.set_counter('gc_steps_sweepstring', 'Count of incremental GC steps (sweepstring state)',
            lj_metrics.gc_steps_sweepstring, nil, LJ_PREFIX)
    collectors_list.gc_strnum =
        utils.set_gauge('gc_strnum', 'Amount of allocated string objects', lj_metrics.gc_strnum, nil, LJ_PREFIX)
    collectors_list.gc_tabnum =
        utils.set_gauge('gc_tabnum', 'Amount of allocated table objects', lj_metrics.gc_tabnum, nil, LJ_PREFIX)
    collectors_list.gc_cdatanum =
        utils.set_gauge('gc_cdatanum', 'Amount of allocated cdata objects', lj_metrics.gc_cdatanum, nil, LJ_PREFIX)
    collectors_list.jit_snap_restore =
        utils.set_counter('jit_snap_restore', 'Overall number of snap restores',
            lj_metrics.jit_snap_restore, nil, LJ_PREFIX)
    collectors_list.gc_total =
        utils.set_gauge('gc_total', 'Memory currently allocated', lj_metrics.gc_total, nil, LJ_PREFIX)
    collectors_list.gc_udatanum =
        utils.set_gauge('gc_udatanum', 'Amount of allocated udata objects', lj_metrics.gc_udatanum, nil, LJ_PREFIX)
    collectors_list.gc_steps_finalize =
        utils.set_counter('gc_steps_finalize', 'Count of incremental GC steps (finalize state)',
            lj_metrics.gc_steps_finalize, nil, LJ_PREFIX)
    collectors_list.gc_allocated =
        utils.set_counter('gc_allocated', 'Total amount of allocated memory', lj_metrics.gc_allocated, nil, LJ_PREFIX)
    collectors_list.jit_trace_num =
        utils.set_gauge('jit_trace_num', 'Amount of JIT traces', lj_metrics.jit_trace_num, nil, LJ_PREFIX)
    collectors_list.gc_steps_sweep =
        utils.set_counter('gc_steps_sweep', 'Count of incremental GC steps (sweep state)',
            lj_metrics.gc_steps_sweep, nil, LJ_PREFIX)
    collectors_list.jit_trace_abort =
        utils.set_counter('jit_trace_abort', 'Overall number of abort traces',
            lj_metrics.jit_trace_abort, nil, LJ_PREFIX)
    collectors_list.jit_mcode_size =
        utils.set_gauge('jit_mcode_size', 'Total size of all allocated machine code areas',
            lj_metrics.jit_mcode_size, nil, LJ_PREFIX)
    collectors_list.gc_steps_propagate =
        utils.set_counter('gc_steps_propagate', 'Count of incremental GC steps (propagate state)',
            lj_metrics.gc_steps_propagate, nil, LJ_PREFIX)
    collectors_list.gc_steps_pause =
        utils.set_counter('gc_steps_pause', 'Count of incremental GC steps (pause state)',
            lj_metrics.gc_steps_pause, nil, LJ_PREFIX)
end

return {
    update = update,
    list = collectors_list,
}
