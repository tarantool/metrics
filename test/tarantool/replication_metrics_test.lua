#!/usr/bin/env tarantool

local t = require('luatest')
local replica_set = require('luatest.replica_set')
local server = require('luatest.server')
local utils = require('test.utils')

local g = t.group('three_member_cluster')


g.before_each(function(cg)
    t.skip_if(utils.is_version_less(_TARANTOOL, '3.0.0'),
        'Tarantool version is must be v3.0.0 or greater')

    cg.replica_set = replica_set:new{}

    cg.master = cg.replica_set:build_and_add_server{
        alias = 'master',
        env = {
            LUA_PATH = utils.LUA_PATH
        }
    }
    t.assert(cg.master)

    cg.master:start()

    local box_cfg = {
        replication = {
            cg.master.net_box_uri,
            server.build_listen_uri('replica', cg.replica_set.id),
            server.build_listen_uri('to_be_deleted', cg.replica_set.id),
        },
        bootstrap_strategy = 'config',
        bootstrap_leader = cg.master.net_box_uri,
    }

    cg.replica_to_be_deleted = cg.replica_set:build_and_add_server{
        alias = 'to_be_deleted',
        box_cfg = box_cfg,
        env = {
            LUA_PATH = utils.LUA_PATH
        }
    }
    cg.replica_to_be_deleted:start()

    cg.replica = cg.replica_set:build_and_add_server{
        alias = 'replica',
        box_cfg = box_cfg,
        env = {
            LUA_PATH = utils.LUA_PATH
        }
    }
    cg.replica:start()

    -- Make `_cluster` space synchronous.
    cg.master:exec(function()
        box.ctl.promote()
        box.space._cluster:alter{is_sync = true}
    end)

    cg.master:wait_for_downstream_to(cg.replica_to_be_deleted)
    cg.master:wait_for_downstream_to(cg.replica)

    cg.master:exec(function()
        require('metrics').clear()
    end)
end)


g.after_each(function(cg)
    cg.replica_set:drop()
end)


g.test_metrics_removed_replica = function(cg)
    t.skip_if(utils.is_version_less(_TARANTOOL, '3.0.0'),
        'Tarantool version is must be v3.0.0 or greater')

    cg.master:exec(function()
        local t = require('luatest') -- luacheck: ignore 431
        local utils = require('test.utils') -- luacheck: ignore 431
        local metrics = require('metrics')
        metrics.enable_default_metrics()

        local info = require('metrics.tarantool.info')
        info.update()

        t.assert(info.list)
        t.assert(info.list.read_only)
        t.assert(info.list.replication_status)

        local default_metrics = metrics.collect()

        t.assert_not_equals(default_metrics, nil)

        -- Check that all metrics equal 1 ('follow').
        local tnt_replication_status = utils.find_metric('tnt_replication_status', default_metrics)
        t.assert(tnt_replication_status)
        t.assert_equals(#tnt_replication_status, 2)
        t.assert_equals(tnt_replication_status[1].value, 1)
        t.assert_equals(tnt_replication_status[2].value, 1)
    end)

    local master_id = cg.master:get_instance_id()
    local deleted_id = cg.replica_to_be_deleted:get_instance_id()

    cg.master:exec(function(id)
        t.assert(box.space._cluster:delete{id})
    end, {deleted_id})

    cg.replica_to_be_deleted:wait_for_vclock_of(cg.master)

    cg.replica_to_be_deleted:exec(function()
        t.helpers.retrying({timeout = 5}, function()
            t.assert_equals(box.info.id, nil)
        end)
    end)

    cg.replica:exec(function(deleted, master)
        t.helpers.retrying({timeout = 5}, function()
            t.assert_equals(box.info.replication[master].upstream.status, 'follow')
            t.assert_equals(box.info.replication[master].upstream.message, nil)
        end)

        t.helpers.retrying({timeout = 5}, function()
            t.assert_equals(box.info.replication[deleted], nil)
        end)
    end, {deleted_id, master_id})

    cg.replica_to_be_deleted:exec(function(master, deleted)
        local msg = "The local instance id " .. deleted .. " is read-only"
        t.helpers.retrying({timeout = 5}, function()
            t.assert_equals(box.info.replication[master].upstream.status, 'stopped')
            t.assert_equals(box.info.replication[master].upstream.message, msg)
        end)
    end, {master_id, deleted_id})

    cg.master:wait_for_downstream_to(cg.replica)

    cg.master:exec(function()
        local t = require('luatest') -- luacheck: ignore 431
        local utils = require('test.utils') -- luacheck: ignore 431
        local metrics = require('metrics')
        metrics.enable_default_metrics()

        local info = require('metrics.tarantool.info')
        info.update()

        local default_metrics = metrics.collect()
        t.assert_not_equals(default_metrics, nil)

        -- Here should be only 1 metric from working replica with value 1 ('follow').
        local tnt_replication_status = utils.find_metric('tnt_replication_status', default_metrics)
        t.assert(tnt_replication_status)
        t.assert_equals(#tnt_replication_status, 1)
        t.assert_equals(tnt_replication_status[1].value, 1)
    end)
end
