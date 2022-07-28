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

    collectors_list.memtx_tx_tnx_statements_max =
        utils.set_gauge('memtx_tx_tnx_statements_max', 'Maximum number of bytes used by one transaction for statements',
            memtx_tx_stat.txn.statements.max)
    collectors_list.memtx_tx_tnx_statements_avg =
        utils.set_gauge('memtx_tx_tnx_statements_avg', 'Average bytes used by transactions for statements',
            memtx_tx_stat.txn.statements.avg)
    collectors_list.memtx_tx_tnx_statements_total =
        utils.set_gauge('memtx_tx_tnx_statements_total',
            'The number of bytes that are allocated for the statements of all transactions',
            memtx_tx_stat.txn.statements.total)

    collectors_list.memtx_tx_tnx_user_max =
        utils.set_gauge('memtx_tx_tnx_user_max',
            'The maximum number of bytes allocated by `box_txn_alloc()` function per transaction',
            memtx_tx_stat.txn.user.max)
    collectors_list.memtx_tx_tnx_user_avg =
        utils.set_gauge('memtx_tx_tnx_user_avg', 'Transaction average (total / number of transactions)',
            memtx_tx_stat.txn.user.avg)
    collectors_list.memtx_tx_tnx_user_total =
        utils.set_gauge('memtx_tx_tnx_user_total',
            'Memory allocated by the `box_txn_alloc()` function on all transactions',
            memtx_tx_stat.txn.user.total)

    collectors_list.memtx_tx_tnx_system_max =
        utils.set_gauge('memtx_tx_tnx_system_max', 'The maximum number of bytes allocated by internals per transaction',
            memtx_tx_stat.txn.system.max)
    collectors_list.memtx_tx_tnx_system_avg =
        utils.set_gauge('memtx_tx_tnx_system_avg',
            'Average allocated memory by internals (total / number of transactions)',
            memtx_tx_stat.txn.system.avg)
    collectors_list.memtx_tx_tnx_system_total =
        utils.set_gauge('memtx_tx_tnx_system_total', 'Memory allocated by internals on all transactions',
            memtx_tx_stat.txn.system.total)

    collectors_list.memtx_tx_mvcc_trackers_max =
        utils.set_gauge('memtx_tx_mvcc_trackers_max', 'Maximum trackers allocated per transaction',
            memtx_tx_stat.mvcc.trackers.max)
    collectors_list.memtx_tx_mvcc_trackers_avg =
        utils.set_gauge('memtx_tx_mvcc_trackers_avg', 'Average for all transactions (total / number of transactions)',
            memtx_tx_stat.mvcc.trackers.avg)
    collectors_list.memtx_tx_mvcc_trackers_total =
        utils.set_gauge('memtx_tx_mvcc_trackers_total', 'Trackers are allocated in total',
            memtx_tx_stat.mvcc.trackers.total)

    collectors_list.memtx_tx_mvcc_conflicts_max =
        utils.set_gauge('memtx_tx_mvcc_conflicts_max', 'Maximum bytes allocated for conflicts per transaction',
            memtx_tx_stat.mvcc.conflicts.max)
    collectors_list.memtx_tx_mvcc_conflicts_avg =
        utils.set_gauge('memtx_tx_mvcc_conflicts_avg', 'Average for all transactions (total / number of transactions)',
            memtx_tx_stat.mvcc.conflicts.avg)
    collectors_list.memtx_tx_mvcc_conflicts_total =
        utils.set_gauge('memtx_tx_mvcc_conflicts_total', 'Bytes allocated for conflicts in total',
            memtx_tx_stat.mvcc.conflicts.total)


    collectors_list.memtx_tx_mvcc_tuples_tracking_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories_count',
            'Number of `tracking` tuples / number of tracking stories.',
            memtx_tx_stat.mvcc.tuples.tracking.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_tracking_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories_total',
            'Amount of bytes used by stories `tracking` tuples',
            memtx_tx_stat.mvcc.tuples.tracking.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_tracking_retained_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_retained_count',
            'Number of retained `tracking` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.tracking.retained.count)
    collectors_list.memtx_tx_mvcc_tuples_tracking_retained_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_retained_total',
            'Amount of bytes used by retained `tracking` tuples',
            memtx_tx_stat.mvcc.tuples.tracking.retained.total)


    collectors_list.memtx_tx_mvcc_tuples_used_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories_count', 'Number of `used` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.used.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_used_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories_total', 'Amount of bytes used by stories ``used`` tuples',
            memtx_tx_stat.mvcc.tuples.used.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_used_retained_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_retained_count',
            'Number of retained `used` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.used.retained.count)
    collectors_list.memtx_tx_mvcc_tuples_used_retained_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_retained_total', 'Amount of bytes used by retained `used` tuples',
            memtx_tx_stat.mvcc.tuples.used.retained.total)


    collectors_list.memtx_tx_mvcc_tuples_read_view_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories_count',
            'Number of `read_view` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.read_view.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_read_view_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories_total',
            'Amount of bytes used by stories `read_view` tuples',
            memtx_tx_stat.mvcc.tuples.read_view.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_read_view_retained_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_retained_count',
            'Number of retained `read_view` tuples / number of stories',
            memtx_tx_stat.mvcc.tuples.read_view.retained.count)
    collectors_list.memtx_tx_mvcc_tuples_read_view_retained_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_retained_total',
            'Amount of bytes used by retained `read_view` tuples',
            memtx_tx_stat.mvcc.tuples.read_view.retained.total)

end

return {
    update = update,
    list = collectors_list,
}
