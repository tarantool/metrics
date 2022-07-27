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
        utils.set_gauge('memtx_tx_tnx_statements_max', '',
            memtx_tx_stat.txn.statements.max)
    collectors_list.memtx_tx_tnx_statements_avg =
        utils.set_gauge('memtx_tx_tnx_statements_avg', '',
            memtx_tx_stat.txn.statements.avg)
    collectors_list.memtx_tx_tnx_statements_total =
        utils.set_gauge('memtx_tx_tnx_statements_total', '',
            memtx_tx_stat.txn.statements.total)

    collectors_list.memtx_tx_tnx_user_max =
        utils.set_gauge('memtx_tx_tnx_user_max', '',
            memtx_tx_stat.txn.user.max)
    collectors_list.memtx_tx_tnx_user_avg =
        utils.set_gauge('memtx_tx_tnx_user_avg', '',
            memtx_tx_stat.txn.user.avg)
    collectors_list.memtx_tx_tnx_user_total =
        utils.set_gauge('memtx_tx_tnx_user_total', '',
            memtx_tx_stat.txn.user.total)

    collectors_list.memtx_tx_tnx_system_max =
        utils.set_gauge('memtx_tx_tnx_system_max', '',
            memtx_tx_stat.txn.system.max)
    collectors_list.memtx_tx_tnx_system_avg =
        utils.set_gauge('memtx_tx_tnx_system_avg', '',
            memtx_tx_stat.txn.system.avg)
    collectors_list.memtx_tx_tnx_system_total =
        utils.set_gauge('memtx_tx_tnx_system_total', '',
            memtx_tx_stat.txn.system.total)

    collectors_list.memtx_tx_mvcc_trackers_max =
        utils.set_gauge('memtx_tx_mvcc_trackers_max', '',
            memtx_tx_stat.mvcc.trackers.max)
    collectors_list.memtx_tx_mvcc_trackers_avg =
        utils.set_gauge('memtx_tx_mvcc_trackers_avg', '',
            memtx_tx_stat.mvcc.trackers.avg)
    collectors_list.memtx_tx_mvcc_trackers_total =
        utils.set_gauge('memtx_tx_mvcc_trackers_total', '',
            memtx_tx_stat.mvcc.trackers.total)

    collectors_list.memtx_tx_mvcc_conflicts_max =
        utils.set_gauge('memtx_tx_mvcc_conflicts_max', '',
            memtx_tx_stat.mvcc.conflicts.max)
    collectors_list.memtx_tx_mvcc_conflicts_avg =
        utils.set_gauge('memtx_tx_mvcc_conflicts_avg', '',
            memtx_tx_stat.mvcc.conflicts.avg)
    collectors_list.memtx_tx_mvcc_conflicts_total =
        utils.set_gauge('memtx_tx_mvcc_conflicts_total', '',
            memtx_tx_stat.mvcc.conflicts.total)


    collectors_list.memtx_tx_mvcc_tuples_tracking_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories_count', '',
            memtx_tx_stat.mvcc.tuples.tracking.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_tracking_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories_total', '',
            memtx_tx_stat.mvcc.tuples.tracking.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_tracking_retained_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_retained_count', '',
            memtx_tx_stat.mvcc.tuples.tracking.retained.count)
    collectors_list.memtx_tx_mvcc_tuples_tracking_retained_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_retained_total', '',
            memtx_tx_stat.mvcc.tuples.tracking.retained.total)


    collectors_list.memtx_tx_mvcc_tuples_used_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories_count', '',
            memtx_tx_stat.mvcc.tuples.used.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_used_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories_total', '',
            memtx_tx_stat.mvcc.tuples.used.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_used_retained_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_retained_count', '',
            memtx_tx_stat.mvcc.tuples.used.retained.count)
    collectors_list.memtx_tx_mvcc_tuples_used_retained_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_retained_total', '',
            memtx_tx_stat.mvcc.tuples.used.retained.total)


    collectors_list.memtx_tx_mvcc_tuples_read_view_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories_count', '',
            memtx_tx_stat.mvcc.tuples.read_view.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_read_view_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories_total', '',
            memtx_tx_stat.mvcc.tuples.read_view.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_read_view_retained_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_retained_count', '',
            memtx_tx_stat.mvcc.tuples.read_view.retained.count)
    collectors_list.memtx_tx_mvcc_tuples_read_view_retained_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_retained_total', '',
            memtx_tx_stat.mvcc.tuples.read_view.retained.total)

end

return {
    update = update,
    list = collectors_list,
}
