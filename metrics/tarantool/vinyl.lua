local utils = require('metrics.utils')

local collectors_list = {}

local function update()
    if not utils.box_is_configured() then
        return
    end

    local vinyl_stat = box.stat.vinyl()
    collectors_list.vinyl_disk_data_size =
        utils.set_gauge('vinyl_disk_data_size', 'Amount of data stored in files', vinyl_stat.disk.data)
    collectors_list.vinyl_disk_index_size =
        utils.set_gauge('vinyl_disk_index_size', 'Amount of index stored in files', vinyl_stat.disk.index)

    collectors_list.vinyl_regulator_dump_bandwidth =
        utils.set_gauge('vinyl_regulator_dump_bandwidth', 'Estimated average rate at which dumps are done',
        vinyl_stat.regulator.dump_bandwidth)
    collectors_list.vinyl_regulator_write_rate =
        utils.set_gauge('vinyl_regulator_write_rate', 'Average rate at which recent writes to disk are done',
        vinyl_stat.regulator.write_rate)
    collectors_list.vinyl_regulator_rate_limit =
        utils.set_gauge('vinyl_regulator_rate_limit', 'Write rate limit', vinyl_stat.regulator.rate_limit)
    collectors_list.vinyl_regulator_dump_watermark =
        utils.set_gauge('vinyl_regulator_dump_watermark', 'Point when dumping must occur',
        vinyl_stat.regulator.dump_watermark)

    collectors_list.vinyl_tx_conflict =
        utils.set_gauge('vinyl_tx_conflict', 'Count of transaction conflicts', vinyl_stat.tx.conflict)
    collectors_list.vinyl_tx_commit =
        utils.set_gauge('vinyl_tx_commit', 'Count of commits', vinyl_stat.tx.commit)
    collectors_list.vinyl_tx_rollback =
        utils.set_gauge('vinyl_tx_rollback', 'Count of rollbacks', vinyl_stat.tx.rollback)
    collectors_list.vinyl_tx_read_views =
        utils.set_gauge('vinyl_tx_read_views', 'Count of open read views', vinyl_stat.tx.read_views)

    collectors_list.vinyl_memory_tuple_cache =
        utils.set_gauge('vinyl_memory_tuple_cache', 'Number of bytes that are being used for tuple',
        vinyl_stat.memory.tuple_cache)
    collectors_list.vinyl_memory_level0 =
        utils.set_gauge('vinyl_memory_level0', 'Size of in-memory storage of an LSM tree', vinyl_stat.memory.level0)
    collectors_list.vinyl_memory_page_index =
        utils.set_gauge('vinyl_memory_page_index', 'Size of page indexes', vinyl_stat.memory.page_index)
    collectors_list.vinyl_memory_bloom_filter =
        utils.set_gauge('vinyl_memory_bloom_filter', 'Size of bloom filter', vinyl_stat.memory.bloom_filter)

    collectors_list.vinyl_scheduler_tasks =
        utils.set_gauge('vinyl_scheduler_tasks', 'Vinyl tasks count', vinyl_stat.scheduler.tasks_inprogress,
        {status = 'inprogress'})
    collectors_list.vinyl_scheduler_tasks =
        utils.set_gauge('vinyl_scheduler_tasks', 'Vinyl tasks count', vinyl_stat.scheduler.tasks_completed,
        {status = 'completed'})
    collectors_list.vinyl_scheduler_tasks =
        utils.set_gauge('vinyl_scheduler_tasks', 'Vinyl tasks count', vinyl_stat.scheduler.tasks_failed,
        {status = 'failed'})

    collectors_list.vinyl_scheduler_dump_time =
        utils.set_gauge('vinyl_scheduler_dump_time', 'Total time spent by all worker threads performing dump',
        vinyl_stat.scheduler.dump_time)
    collectors_list.vinyl_scheduler_dump_count =
        utils.set_gauge('vinyl_scheduler_dump_count', 'The count of completed dumps', vinyl_stat.scheduler.dump_count)
    collectors_list.vinyl_scheduler_dump_total =
        utils.set_counter('vinyl_scheduler_dump_total', 'The count of completed dumps', vinyl_stat.scheduler.dump_count)
end

return {
    update = update,
    list = collectors_list,
}
