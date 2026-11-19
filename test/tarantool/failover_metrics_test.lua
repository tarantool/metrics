#!/usr/bin/env tarantool

local t = require('luatest')
local fiber = require('fiber')
local metrics = require('metrics')
local failover = require('metrics.tarantool.failover')
local utils = require('test.utils')
local g = t.group('failover_metrics')

local function configure(include, exclude, labels)
    metrics.cfg{
        include = include or {'failover'},
        exclude = exclude or {},
        labels = labels or {alias = 'coordinator-uuid'},
    }
end

local function collect()
    return metrics.collect{invoke_callbacks = true}
end

local function snapshot()
    return {
        alias = 'coordinator-uuid',
        active = true,
        replicasets = {rs1 = {instance1 = 'alive'}},
    }
end

local function reset()
    failover.set_source(nil)
    metrics.clear()
end

g.before_each(reset)
g.after_each(reset)

-- Collection without a source produces no failover observations.
g.test_no_source = function()
    configure()
    t.assert_equals(collect(), {})
    t.assert_equals(failover.list, {})
end

-- Registering a source leaves collection disabled until the group is enabled.
g.test_registration_does_not_enable = function()
    configure('none')
    local calls = 0
    failover.set_source(function()
        calls = calls + 1
        return snapshot()
    end)
    t.assert_equals(collect(), {})
    t.assert_equals(calls, 0)
    t.assert_equals(failover.list, {})
    configure()
    t.assert_equals(#collect(), 2)
    t.assert_equals(calls, 1)
end

-- Each collection reads fresh state without yielding or changing the snapshot.
g.test_fresh_read_only_snapshot = function()
    local state = snapshot()
    local calls = 0
    failover.set_source(function()
        calls = calls + 1
        return state
    end)
    configure()
    local original = table.deepcopy(state)
    local csw = fiber.self():csw()
    local observations = collect()
    t.assert_equals(fiber.self():csw(), csw)
    t.assert_equals(state, original)
    utils.assert_observations(observations, {
        {'tarantool_coordinator_active', 1, {alias = 'coordinator-uuid'}},
        {'tarantool_instance_status', 1, {
            alias = 'coordinator-uuid', replicaset = 'rs1',
            instance = 'instance1',
        }},
    })
    state.active = false
    state.replicasets.rs1.instance1 = 'uncallable'
    observations = collect()
    t.assert_equals(calls, 2)
    t.assert_equals(utils.find_metric('tarantool_coordinator_active',
        observations)[1].value, 0)
    t.assert_equals(utils.find_metric('tarantool_instance_status',
        observations)[1].value, 0)
    for _, collector in pairs(failover.list) do
        t.assert_equals(collector.kind, 'gauge')
        t.assert_equals(collector.metainfo.default, true)
    end
end

-- Only alive instances report 1; other and missing statuses report 0.
g.test_statuses = function()
    failover.set_source(function()
        return {
            active = false,
            replicasets = {rs1 = {
                alive = 'alive', dead = 'dead', unknown = 'unknown',
                uncallable = 'uncallable', missing = false,
            }},
        }
    end)
    configure()
    local observations = collect()
    t.assert_equals(#observations, 6)
    for _, observation in ipairs(utils.find_metric('tarantool_instance_status',
        observations)) do
        local name = observation.label_pairs.instance
        t.assert_equals(observation.value, name == 'alive' and 1 or 0)
    end
end

-- Global labels can change alias but cannot override local instance labels.
g.test_global_labels = function()
    failover.set_source(snapshot)
    configure(nil, nil, {
        alias = 'explicit-alias', custom = 'label',
        replicaset = 'wrong-rs', instance = 'wrong-instance',
    })
    local observations = collect()
    local labels = utils.find_metric('tarantool_instance_status',
        observations)[1].label_pairs
    t.assert_equals(labels, {
        alias = 'explicit-alias', custom = 'label',
        replicaset = 'rs1', instance = 'instance1',
    })
    t.assert_equals(utils.find_metric('tarantool_coordinator_active',
        observations)[1].label_pairs.alias, 'explicit-alias')
    metrics.set_global_labels{alias = 'changed'}
    observations = collect()
    t.assert_equals(#observations, 2)
    for _, observation in ipairs(observations) do
        t.assert_equals(observation.label_pairs.alias, 'changed')
    end
    metrics.set_global_labels{}
    observations = collect()
    t.assert_equals(utils.find_metric('tarantool_coordinator_active',
        observations)[1].label_pairs, {})
end

-- Removed or moved instances and replicasets leave no stale observations.
g.test_removed_and_moved_instances = function()
    local state = snapshot()
    state.replicasets.rs1.removed = 'alive'
    state.replicasets.removed_rs = {removed_instance = 'alive'}
    failover.set_source(function() return state end)
    configure()
    t.assert_equals(#collect(), 4)
    state.replicasets = {rs2 = {instance1 = 'alive'}}
    utils.assert_observations(collect(), {
        {'tarantool_coordinator_active', 1, {alias = 'coordinator-uuid'}},
        {'tarantool_instance_status', 1, {
            alias = 'coordinator-uuid', replicaset = 'rs2',
            instance = 'instance1',
        }},
    })
    state.replicasets = {}
    utils.assert_observations(collect(), {
        {'tarantool_coordinator_active', 1, {alias = 'coordinator-uuid'}},
    })
end

-- Replacing or detaching the source immediately clears old observations.
g.test_replace_and_detach = function()
    failover.set_source(snapshot)
    configure()
    collect()
    failover.set_source(function()
        return {active = false, replicasets = {rs2 = {other = false}}}
    end)
    t.assert_equals(metrics.collect(), {})
    utils.assert_observations(collect(), {
        {'tarantool_coordinator_active', 0, {alias = 'coordinator-uuid'}},
        {'tarantool_instance_status', 0, {
            alias = 'coordinator-uuid', replicaset = 'rs2', instance = 'other',
        }},
    })
    failover.set_source(nil)
    t.assert_equals(metrics.collect(), {})
    t.assert_equals(collect(), {})
    t.assert_equals(failover.list, {})
end

-- Disabling clears collectors; re-enabling reads the retained source afresh.
g.test_disable_and_reenable = function()
    local calls = 0
    local state = snapshot()
    failover.set_source(function()
        calls = calls + 1
        return state
    end)
    configure()
    collect()
    configure({'failover'}, {'failover'})
    t.assert_equals(collect(), {})
    t.assert_equals(calls, 1)
    t.assert_equals(failover.list, {})
    t.assert_equals(metrics.collectors(), {})
    t.assert_equals(metrics.registry.callbacks[failover.update], nil)
    state.replicasets = {new_rs = {new_instance = 'alive'}}
    configure()
    local observations = collect()
    t.assert_equals(calls, 2)
    t.assert_equals(#observations, 2)
    t.assert_equals(utils.find_metric('tarantool_instance_status',
        observations)[1].label_pairs, {
            alias = 'coordinator-uuid', replicaset = 'new_rs',
            instance = 'new_instance',
        })
end

-- Source errors propagate even after an earlier successful collection.
g.test_source_error_propagates = function()
    local broken = false
    failover.set_source(function()
        if broken then
            error('snapshot failed')
        end
        return snapshot()
    end)
    configure()
    collect()
    broken = true
    t.assert_error_msg_contains('snapshot failed', collect)
end

-- Source registration rejects values other than a function or nil.
g.test_invalid_source = function()
    t.assert_error_msg_contains('function', failover.set_source, {})
end

-- The failover group leaves uptime collection to the info group.
g.test_uptime_is_not_failover = function()
    failover.set_source(snapshot)
    configure()
    t.assert_equals(utils.find_metric('tnt_info_uptime', collect()), nil)
end
