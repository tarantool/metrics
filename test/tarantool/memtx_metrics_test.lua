#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('memtx_metric')
local utils = require('test.utils')

g.before_all(utils.create_server)

g.after_all(utils.drop_server)

g.before_each(function(cg)
    cg.server:exec(function() require('metrics').clear() end)
end)

g.test_memtx = function(cg)
    t.skip_if(utils.is_version_less(_TARANTOOL, '2.10.0'),
        'Tarantool version is must be v2.10.0 or greater')

    cg.server:exec(function()
        local metrics = require('metrics')
        local memtx = require('metrics.tarantool.memtx')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.enable_default_metrics()
        memtx.update()
        local default_metrics = metrics.collect()
        local log = require('log')

        local metrics_list1 = {
            'tnt_memtx_tnx_statements',
            'tnt_memtx_tnx_user',
            'tnt_memtx_tnx_system',
            'tnt_memtx_mvcc_trackers',
            'tnt_memtx_mvcc_conflicts',
        }

        for _, item in ipairs(metrics_list1) do
            log.info('checking metric: ' .. item)
            local metric = utils.find_metric(item, default_metrics)
            t.assert(metric)
            t.assert_type(metric[1].value, 'number')
            t.assert_items_equals(metric[1].label_pairs, {kind = "average"})
            t.assert_items_equals(metric[2].label_pairs, {kind = "total"})
            t.assert_items_equals(metric[3].label_pairs, {kind = "max"})
        end

        local metrics_list2 = {
            'tnt_memtx_mvcc_tuples_tracking_stories',
            'tnt_memtx_mvcc_tuples_tracking_retained',
            'tnt_memtx_mvcc_tuples_used_stories',
            'tnt_memtx_mvcc_tuples_used_retained',
            'tnt_memtx_mvcc_tuples_read_view_stories',
            'tnt_memtx_mvcc_tuples_read_view_retained',
        }

        for _, item in ipairs(metrics_list2) do
            log.info('checking metric: ' .. item)
            local metric = utils.find_metric(item, default_metrics)
            t.assert(metric)
            t.assert_type(metric[1].value, 'number')
            t.assert_items_equals(metric[1].label_pairs, {kind = "total"})
            t.assert_items_equals(metric[2].label_pairs, {kind = "count"})
        end
    end)
end
