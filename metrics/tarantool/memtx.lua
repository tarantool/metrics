local utils = require('metrics.utils')

local collectors_list = {}

local function update()
    if not utils.box_is_configured() then
        return
    end

    if box.stat.memtx == nil or box.stat.memtx.tx() == nil then
        return
    end

    local memtx_stat = box.stat.memtx.tx()

    collectors_list.memtx_tx_tnx_statements_max =
        utils.set_gauge('memtx_tx_tnx_statements_max', '',
            memtx_stat.txn.statements.max)
    collectors_list.memtx_tx_tnx_statements_avg =
        utils.set_gauge('memtx_tx_tnx_statements_avg', '',
            memtx_stat.txn.statements.avg)
    collectors_list.memtx_tx_tnx_statements_total =
        utils.set_gauge('memtx_tx_tnx_statements_total', '',
            memtx_stat.txn.statements.total)

    collectors_list.memtx_tx_mvcc_trackers_max =
        utils.set_gauge('memtx_tx_mvcc_trackers_max', '',
            memtx_stat.mvcc.trackers.max)
    collectors_list.memtx_tx_mvcc_trackers_avg =
        utils.set_gauge('memtx_tx_mvcc_trackers_avg', '',
            memtx_stat.mvcc.trackers.avg)
    collectors_list.memtx_tx_mvcc_trackers_total =
        utils.set_gauge('memtx_tx_mvcc_trackers_total', '',
            memtx_stat.mvcc.trackers.total)

    collectors_list.memtx_tx_mvcc_conflicts_max =
        utils.set_gauge('memtx_tx_mvcc_conflicts_max', '',
            memtx_stat.mvcc.conflicts.max)
    collectors_list.memtx_tx_mvcc_conflicts_avg =
        utils.set_gauge('memtx_tx_mvcc_conflicts_avg', '',
            memtx_stat.mvcc.conflicts.avg)
    collectors_list.memtx_tx_mvcc_conflicts_total =
        utils.set_gauge('memtx_tx_mvcc_conflicts_total', '',
            memtx_stat.mvcc.conflicts.total)

    collectors_list.memtx_tx_mvcc_tuples_tracking_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories_count', '',
            memtx_stat.mvcc.tuples.tracking.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_tracking_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_tracking_stories_total', '',
            memtx_stat.mvcc.tuples.tracking.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_used_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories_count', '',
            memtx_stat.mvcc.tuples.used.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_used_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_used_stories_total', '',
            memtx_stat.mvcc.tuples.used.stories.total)

    collectors_list.memtx_tx_mvcc_tuples_read_view_stories_count =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories_count', '',
            memtx_stat.mvcc.tuples.read_view.stories.count)
    collectors_list.memtx_tx_mvcc_tuples_read_view_stories_total =
        utils.set_gauge('memtx_tx_mvcc_tuples_read_view_stories_total', '',
            memtx_stat.mvcc.tuples.read_view.stories.total)
end

return {
    update = update,
    list = collectors_list,
}
