#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('info_metric')
local utils = require('test.utils')

g.before_all(utils.create_server)

g.after_all(utils.drop_server)

g.before_each(function(cg)
    cg.server:exec(function() require('metrics').clear() end)
end)

g.test_info = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local info = require('metrics.tarantool.info')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.enable_default_metrics()
        info.update()
        local default_metrics = metrics.collect()

        local tnt_info_lsn = utils.find_metric('tnt_info_lsn', default_metrics)
        t.assert(tnt_info_lsn)
        t.assert_type(tnt_info_lsn[1].value, 'number')

        local tnt_info_uptime = utils.find_metric('tnt_info_uptime', default_metrics)
        t.assert(tnt_info_uptime)
        t.assert_type(tnt_info_uptime[1].value, 'number')
    end)
end

g.test_synchro_queue = function(cg)
    t.skip_if(utils.is_version_less(_TARANTOOL, '2.7.0'),
        'Tarantool version is must be v2.7.0 or greater')

    cg.server:exec(function()
        local metrics = require('metrics')
        local info = require('metrics.tarantool.info')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.enable_default_metrics()
        info.update()
        local default_metrics = metrics.collect()

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
    end)
end

g.test_election = function(cg)
    t.skip_if(utils.is_version_less(_TARANTOOL, '2.7.0'),
        'Tarantool version is must be v2.7.0 or greater')

    cg.server:exec(function()
        local metrics = require('metrics')
        local info = require('metrics.tarantool.info')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.enable_default_metrics()
        info.update()
        local default_metrics = metrics.collect()

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
    end)
end
