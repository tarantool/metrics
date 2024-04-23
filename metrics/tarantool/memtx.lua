local utils = require('metrics.utils')

local collectors_list = {}

local function update()
    if not utils.box_is_configured() then
        return
    end

    if box.stat.memtx == nil or box.stat.memtx.tx == nil then
        return
    end

    local memtx_stat = box.stat.memtx.tx()

    collectors_list.memtx_tnx_statements =
        utils.set_gauge('memtx_tnx_statements', 'Number of bytes used for statements',
            memtx_stat.txn.statements.max, {kind = "max"}, nil, {default = true})
    collectors_list.memtx_tnx_statements =
        utils.set_gauge('memtx_tnx_statements', 'Number of bytes used for statements',
            memtx_stat.txn.statements.avg, {kind = "average"}, nil, {default = true})
    collectors_list.memtx_tnx_statements =
        utils.set_gauge('memtx_tnx_statements', 'Number of bytes used for statements',
            memtx_stat.txn.statements.total, {kind = "total"}, nil, {default = true})

    collectors_list.memtx_tnx_user =
        utils.set_gauge('memtx_tnx_user',
            'Number of bytes allocated by `box_txn_alloc()` function per transaction',
            memtx_stat.txn.user.max, {kind = "max"}, nil, {default = true})
    collectors_list.memtx_tnx_user =
        utils.set_gauge('memtx_tnx_user',
            'Number of bytes allocated by `box_txn_alloc()` function per transaction',
            memtx_stat.txn.user.avg, {kind = "average"}, nil, {default = true})
    collectors_list.memtx_tnx_user =
        utils.set_gauge('memtx_tnx_user',
            'Number of bytes allocated by `box_txn_alloc()` function per transaction',
            memtx_stat.txn.user.total, {kind = "total"}, nil, {default = true})

    collectors_list.memtx_tnx_system =
        utils.set_gauge('memtx_tnx_system',
            'Number of bytes allocated by internals per transaction',
            memtx_stat.txn.system.max, {kind = "max"}, nil, {default = true})
    collectors_list.memtx_tnx_system =
        utils.set_gauge('memtx_tnx_system',
            'Number of bytes allocated by internals per transaction',
            memtx_stat.txn.system.avg, {kind = "average"}, nil, {default = true})
    collectors_list.memtx_tnx_system =
        utils.set_gauge('memtx_tnx_system',
            'Number of bytes allocated by internals per transaction',
            memtx_stat.txn.system.total, {kind = "total"}, nil, {default = true})

    collectors_list.memtx_mvcc_trackers =
        utils.set_gauge('memtx_mvcc_trackers', 'Trackers allocated per transaction',
            memtx_stat.mvcc.trackers.max, {kind = "max"}, nil, {default = true})
    collectors_list.memtx_mvcc_trackers =
        utils.set_gauge('memtx_mvcc_trackers', 'Trackers allocated per transaction',
            memtx_stat.mvcc.trackers.avg, {kind = "average"}, nil, {default = true})
    collectors_list.memtx_mvcc_trackers =
        utils.set_gauge('memtx_mvcc_trackers', 'Trackers allocated per transaction',
            memtx_stat.mvcc.trackers.total, {kind = "total"}, nil, {default = true})

    collectors_list.memtx_mvcc_conflicts =
        utils.set_gauge('memtx_mvcc_conflicts', 'Bytes allocated for conflicts per transaction',
            memtx_stat.mvcc.conflicts.max, {kind = "max"}, nil, {default = true})
    collectors_list.memtx_mvcc_conflicts =
        utils.set_gauge('memtx_mvcc_conflicts', 'Bytes allocated for conflicts per transaction',
            memtx_stat.mvcc.conflicts.avg, {kind = "average"}, nil, {default = true})
    collectors_list.memtx_mvcc_conflicts =
        utils.set_gauge('memtx_mvcc_conflicts', 'Bytes allocated for conflicts per transaction',
            memtx_stat.mvcc.conflicts.total, {kind = "total"}, nil, {default = true})


    collectors_list.memtx_mvcc_tuples_tracking_stories =
        utils.set_gauge('memtx_mvcc_tuples_tracking_stories',
            'Number of `tracking` tuples / number of tracking stories.',
            memtx_stat.mvcc.tuples.tracking.stories.count, {kind = "count"}, nil, {default = true})
    collectors_list.memtx_mvcc_tuples_tracking_stories =
        utils.set_gauge('memtx_mvcc_tuples_tracking_stories',
            'Number of `tracking` tuples / number of tracking stories.',
            memtx_stat.mvcc.tuples.tracking.stories.total, {kind = "total"}, nil, {default = true})

    collectors_list.memtx_mvcc_tuples_tracking_retained =
        utils.set_gauge('memtx_mvcc_tuples_tracking_retained',
            'Number of retained `tracking` tuples / number of stories',
            memtx_stat.mvcc.tuples.tracking.retained.count, {kind = "count"}, nil, {default = true})
    collectors_list.memtx_mvcc_tuples_tracking_retained =
        utils.set_gauge('memtx_mvcc_tuples_tracking_retained',
            'Number of retained `tracking` tuples / number of stories',
            memtx_stat.mvcc.tuples.tracking.retained.total, {kind = "total"}, nil, {default = true})


    collectors_list.memtx_mvcc_tuples_used_stories =
        utils.set_gauge('memtx_mvcc_tuples_used_stories', 'Number of `used` tuples / number of stories',
            memtx_stat.mvcc.tuples.used.stories.count, {kind = "count"}, nil, {default = true})
    collectors_list.memtx_mvcc_tuples_used_stories =
        utils.set_gauge('memtx_mvcc_tuples_used_stories', 'Number of `used` tuples / number of stories',
            memtx_stat.mvcc.tuples.used.stories.total, {kind = "total"}, nil, {default = true})

    collectors_list.memtx_mvcc_tuples_used_retained =
        utils.set_gauge('memtx_mvcc_tuples_used_retained', 'Number of retained `used` tuples / number of stories',
            memtx_stat.mvcc.tuples.used.retained.count, {kind = "count"}, nil, {default = true})
    collectors_list.memtx_mvcc_tuples_used_retained =
        utils.set_gauge('memtx_mvcc_tuples_used_retained', 'Number of retained `used` tuples / number of stories',
            memtx_stat.mvcc.tuples.used.retained.total, {kind = "total"}, nil, {default = true})


    collectors_list.memtx_mvcc_tuples_read_view_stories =
        utils.set_gauge('memtx_mvcc_tuples_read_view_stories',
            'Number of `read_view` tuples / number of stories',
            memtx_stat.mvcc.tuples.read_view.stories.count, {kind = "count"}, nil, {default = true})
    collectors_list.memtx_mvcc_tuples_read_view_stories =
        utils.set_gauge('memtx_mvcc_tuples_read_view_stories',
            'Number of `read_view` tuples / number of stories',
            memtx_stat.mvcc.tuples.read_view.stories.total, {kind = "total"}, nil, {default = true})

    collectors_list.memtx_mvcc_tuples_read_view_retained =
        utils.set_gauge('memtx_mvcc_tuples_read_view_retained',
            'Number of retained `read_view` tuples / number of stories',
            memtx_stat.mvcc.tuples.read_view.retained.count, {kind = "count"}, nil, {default = true})
    collectors_list.memtx_mvcc_tuples_read_view_retained =
        utils.set_gauge('memtx_mvcc_tuples_read_view_retained',
            'Number of retained `read_view` tuples / number of stories',
            memtx_stat.mvcc.tuples.read_view.retained.total, {kind = "total"}, nil, {default = true})

    -- Tarantool 3.0 memory statistics

    local ok, memtx_stat_3 = pcall(box.stat.memtx)
    if not ok or memtx_stat_3.data == nil or memtx_stat_3.index == nil then
        return
    end

    collectors_list.memtx_tuples_data_total =
        utils.set_gauge('memtx_tuples_data_total',
            'Total amount of memory allocated for data tuples',
            memtx_stat_3.data.total, nil, nil, {default = true})
    collectors_list.memtx_tuples_data_read_view =
        utils.set_gauge('memtx_tuples_data_read_view',
            'Memory held for read views',
            memtx_stat_3.data.read_view, {kind = "read_view"}, nil, {default = true})
    collectors_list.memtx_tuples_data_garbage =
        utils.set_gauge('memtx_tuples_data_garbage',
            'Memory that is unused and scheduled to be freed',
            memtx_stat_3.data.garbage, nil, nil, {default = true})


    collectors_list.memtx_index_total =
        utils.set_gauge('memtx_index_total',
            'Total amount of memory allocated for indexing data',
            memtx_stat_3.index.total, nil, nil, {default = true})
    collectors_list.memtx_index_extents_read_view =
        utils.set_gauge('memtx_index_extents_read_view',
            'Memory held for read views',
            memtx_stat_3.index.read_view, nil, nil, {default = true})

end

return {
    update = update,
    list = collectors_list,
}
