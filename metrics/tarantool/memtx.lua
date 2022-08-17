local utils = require('metrics.utils')

local collectors_list = {}

local function update()
    if not utils.box_is_configured() then
        return
    end

    if box.stat.memtx == nil or box.stat.memtx.tx() == nil then
        return
    end

    local memtx_tx_stat = box.stat.memtx.tx()

    collectors_list.memtx_tx_tnx_statements =
        utils.set_gauge('memtx_tx_tnx_statements', 'Maximum number of bytes used by one transaction for statements',
            memtx_tx_stat.txn.statements.max, {kind = "max"})
    collectors_list.memtx_tx_tnx_statements =
        utils.set_gauge('memtx_tx_tnx_statements', 'Average bytes used by transactions for statements',
            memtx_tx_stat.txn.statements.avg, {kind = "average"})
    collectors_list.memtx_tx_tnx_statements =
        utils.set_gauge('memtx_tx_tnx_statements',
            'The number of bytes that are allocated for the statements of all current transactions',
            memtx_tx_stat.txn.statements.total, {kind = "total"})

    collectors_list.memtx_tx_tnx_user =
        utils.set_gauge('memtx_tx_tnx_user',
            'The maximum number of bytes allocated by `box_txn_alloc()` function per transaction',
            memtx_tx_stat.txn.user.max, {kind = "max"})
    collectors_list.memtx_tx_tnx_user =
        utils.set_gauge('memtx_tx_tnx_user', 'Transaction average (total memory / number of all current transactions)',
            memtx_tx_stat.txn.user.avg, {kind = "average"})
    collectors_list.memtx_tx_tnx_user =
        utils.set_gauge('memtx_tx_tnx_user',
            'Memory allocated by the `box_txn_alloc()` function on all current transactions',
            memtx_tx_stat.txn.user.total, {kind = "total"})

    collectors_list.memtx_tx_tnx_system =
        utils.set_gauge('memtx_tx_tnx_system', 'The maximum number of bytes allocated by internals per transaction',
            memtx_tx_stat.txn.system.max, {kind = "max"})
    collectors_list.memtx_tx_tnx_system =
        utils.set_gauge('memtx_tx_tnx_system',
            'Average allocated memory by internals (total memory / number of all current transactions)',
            memtx_tx_stat.txn.system.avg, {kind = "average"})
    collectors_list.memtx_tx_tnx_system =
        utils.set_gauge('memtx_tx_tnx_system', 'Memory allocated by internals on all  transactions',
            memtx_tx_stat.txn.system.total, {kind = "total"})

    collectors_list.memtx_tx_mvcc_trackers =
        utils.set_gauge('memtx_tx_mvcc_trackers', 'Maximum trackers allocated per transaction',
            memtx_tx_stat.mvcc.trackers.max, {kind = "max"})
    collectors_list.memtx_tx_mvcc_trackers =
        utils.set_gauge('memtx_tx_mvcc_trackers',
            'Average for all current transactions (total memory / number of transactions)',
            memtx_tx_stat.mvcc.trackers.avg, {kind = "average"})
    collectors_list.memtx_tx_mvcc_trackers =
        utils.set_gauge('memtx_tx_mvcc_trackers', 'Trackers are allocated in total',
            memtx_tx_stat.mvcc.trackers.total, {kind = "total"})

    collectors_list.memtx_tx_mvcc_conflicts =
        utils.set_gauge('memtx_tx_mvcc_conflicts', 'Maximum bytes allocated for conflicts per transaction',
            memtx_tx_stat.mvcc.conflicts.max, {kind = "max"})
    collectors_list.memtx_tx_mvcc_conflicts =
        utils.set_gauge('memtx_tx_mvcc_conflicts',
            'Average for all current transactions (total memory / number of transactions)',
            memtx_tx_stat.mvcc.conflicts.avg, {kind = "average"})
    collectors_list.memtx_tx_mvcc_conflicts =
        utils.set_gauge('memtx_tx_mvcc_conflicts', 'Bytes allocated for conflicts in total',
            memtx_tx_stat.mvcc.conflicts.total, {kind = "total"})


    collectors_list.memtx_tx_mvcc_tuples_tracking_stories =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories',
            'Number of `tracking` tuples / number of tracking stories.',
            memtx_tx_stat.mvcc.tuples.tracking.stories.count, {kind = "count"})
    collectors_list.memtx_tx_mvcc_tuples_tracking_stories =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories', 'Amount of bytes used by stories `tracking` tuples',
            memtx_tx_stat.mvcc.tuples.tracking.stories.total, {kind = "total"})

    collectors_list.memtx_tx_mvcc_tuples_tracking_retained =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_retained',
            'Number of retained `tracking` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.tracking.retained.count, {kind = "count"})
    collectors_list.memtx_tx_mvcc_tuples_tracking_retained =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_retained', 'Amount of bytes used by retained `tracking` tuples',
            memtx_tx_stat.mvcc.tuples.tracking.retained.total, {kind = "total"})


    collectors_list.memtx_tx_mvcc_tuples_used_stories =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories', 'Number of `used` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.used.stories.count, {kind = "count"})
    collectors_list.memtx_tx_mvcc_tuples_used_stories =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories', 'Amount of bytes used by stories ``used`` tuples',
            memtx_tx_stat.mvcc.tuples.used.stories.total, {kind = "total"})

    collectors_list.memtx_tx_mvcc_tuples_used_retained =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_retained', 'Number of retained `used` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.used.retained.count, {kind = "count"})
    collectors_list.memtx_tx_mvcc_tuples_used_retained =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_retained', 'Amount of bytes used by retained `used` tuples',
            memtx_tx_stat.mvcc.tuples.used.retained.total, {kind = "total"})


    collectors_list.memtx_tx_mvcc_tuples_read_view_stories =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories',
            'Number of `read_view` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.read_view.stories.count, {kind = "count"})
    collectors_list.memtx_tx_mvcc_tuples_read_view_stories =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories',
            'Amount of bytes used by stories `read_view` tuples',
            memtx_tx_stat.mvcc.tuples.read_view.stories.total, {kind = "total"})

    collectors_list.memtx_tx_mvcc_tuples_read_view_retained =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_retained',
            'Number of retained `read_view` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.read_view.retained.count, {kind = "count"})
    collectors_list.memtx_tx_mvcc_tuples_read_view_retained =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_retained',
            'Amount of bytes used by retained `read_view` tuples',
            memtx_tx_stat.mvcc.tuples.read_view.retained.total, {kind = "total"})

end

return {
    update = update,
    list = collectors_list,
}
