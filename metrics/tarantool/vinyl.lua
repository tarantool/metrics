local utils = require('metrics.utils')

local function update_memory_metrics()
    if not utils.box_is_configured() then
        return
    end

    local vinyl_stat = box.stat.vinyl()
    utils.set_gauge('vinyl_disk_data_size', 'Amount of data that has gone into files', vinyl_stat.disk.data)
    utils.set_gauge('vinyl_disk_index_size', 'Amount of index that has gone into files', vinyl_stat.disk.index)
    utils.set_gauge('vinyl_disk_data_compacted_size', 'Amount of index that has gone into files', vinyl_stat.disk.data_compacted)

    utils.set_gauge('vinyl_regulator_dump_bandwidth', 'Estimated average rate at which dumps are done', vinyl_stat.regulator.dump_bandwidth)
    utils.set_gauge('vinyl_regulator.write_rate', 'Average rate at which recent writes to disk are done', vinyl_stat.regulator.write_rate)
    utils.set_gauge('vinyl_regulator.rate_limit', 'Write rate limit', vinyl_stat.regulator.rate_limit)

    utils.set_gauge('vinyl_tx.conflict', 'Count of conflicts that caused a transaction to roll back', vinyl_stat.tx.conflict)
    utils.set_gauge('vinyl_tx.commit', '', vinyl_stat.tx.commit)
    utils.set_gauge('vinyl_tx.rollback', '', vinyl_stat.tx.rollback)

    utils.set_gauge('vinyl_memory.tuple_cache', '', vinyl_stat.memory.tuple_cache)
    utils.set_gauge('vinyl_memory.level0', '', vinyl_stat.memory.level0)
    utils.set_gauge('vinyl_memory.page_index', '', vinyl_stat.memory.page_index)
    utils.set_gauge('vinyl_memory.bloom_filter', '', vinyl_stat.memory.bloom_filter)

    utils.set_gauge('vinyl_scheduler.compaction_input', '', vinyl_stat.scheduler.compaction_input)
    utils.set_gauge('vinyl_scheduler.compaction_time', '', vinyl_stat.scheduler.compaction_time)
    utils.set_gauge('vinyl_scheduler.compaction_output', '', vinyl_stat.scheduler.compaction_output)
    utils.set_gauge('vinyl_scheduler.compaction_queue', '', vinyl_stat.scheduler.compaction_queue)

    utils.set_gauge('vinyl_scheduler.tasks_inprogress', '', vinyl_stat.scheduler.tasks_inprogress)
    utils.set_gauge('vinyl_scheduler.tasks_completed', '', vinyl_stat.scheduler.tasks_completed)
    utils.set_gauge('vinyl_scheduler.tasks_failed', '', vinyl_stat.scheduler.tasks_failed)

    utils.set_gauge('vinyl_scheduler.dump_time', '', vinyl_stat.scheduler.dump_time)
    utils.set_gauge('vinyl_scheduler.dump_output', '', vinyl_stat.scheduler.dump_output)
    utils.set_gauge('vinyl_scheduler.dump_count', '', vinyl_stat.scheduler.dump_count)
    utils.set_gauge('vinyl_scheduler.dump_input', '', vinyl_stat.scheduler.dump_input)
end

return {
    update = update_memory_metrics
}
