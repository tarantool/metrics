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

    local metrics_list = {
        'tnt_info_lsn',
        'tnt_info_uptime',
        'tnt_synchro_queue_owner',
        'tnt_synchro_queue_term',
        'tnt_synchro_queue_len',
        'tnt_synchro_queue_busy',
        'tnt_election_state',
        'tnt_election_vote',
        'tnt_election_leader',
        'tnt_election_term',
    }

    for _, item in ipairs(metrics_list) do
        require('log').info('checking metric: ' .. item)
        local metric = utils.find_metric(item, default_metrics)
        t.assert(metric)
        t.assert_type(metric[1].value, 'number')
    end
end
