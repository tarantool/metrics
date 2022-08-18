#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('info_metric')
local info = require('metrics.tarantool.info')
local utils = require('test.utils')

local metrics = require('metrics')

g.before_all(utils.init)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
end)

g.test_info = function()
    metrics.enable_default_metrics()
    info.update()
    local default_metrics = metrics.collect()

    local tnt_info_lsn = utils.find_metric('tnt_info_lsn', default_metrics)
    t.assert(tnt_info_lsn)
    t.assert_type(tnt_info_lsn[1].value, 'number')

    local tnt_info_uptime = utils.find_metric('tnt_info_uptime', default_metrics)
    t.assert(tnt_info_uptime)
    t.assert_type(tnt_info_uptime[1].value, 'number')

    t.skip_if(utils.is_version_less(_TARANTOOL, '2.8.0'),
        'Tarantool version is must be v2.8.0 or greater')

    local tnt_synchro_queue_owner = utils.find_metric('tnt_synchro_queue_owner', default_metrics)
    t.assert(tnt_synchro_queue_owner)
    t.assert_type(tnt_synchro_queue_owner[1].value, 'number')

    local tnt_synchro_queue_term = utils.find_metric('tnt_synchro_queue_term', default_metrics)
    t.assert(tnt_synchro_queue_term)
    t.assert_type(tnt_synchro_queue_term[1].value, 'number')

    local tnt_synchro_queue_len = utils.find_metric('tnt_synchro_queue_len', default_metrics)
    t.assert(tnt_synchro_queue_len)
    t.assert_type(tnt_synchro_queue_len[1].value, 'number')

    local tnt_synchro_queue_busy = utils.find_metric('tnt_synchro_queue_busy', default_metrics)
    t.assert(tnt_synchro_queue_busy)
    t.assert_type(tnt_synchro_queue_busy[1].value, 'number')

    local tnt_election_state = utils.find_metric('tnt_election_state', default_metrics)
    t.assert(tnt_election_state)
    t.assert_type(tnt_election_state[1].value, 'number')

    local tnt_election_vote = utils.find_metric('tnt_election_vote', default_metrics)
    t.assert(tnt_election_vote)
    t.assert_type(tnt_election_vote[1].value, 'number')

    local tnt_election_leader = utils.find_metric('tnt_election_leader', default_metrics)
    t.assert(tnt_election_leader)
    t.assert_type(tnt_election_leader[1].value, 'number')

    local tnt_election_term = utils.find_metric('tnt_election_term', default_metrics)
    t.assert(tnt_election_term)
    t.assert_type(tnt_election_term[1].value, 'number')
end
