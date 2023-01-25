local utils = require('metrics.utils')

local collectors_list = {}

local function update()
    if not utils.box_is_configured() then
        return
    end

    local vinyl_stat = box.stat.vinyl()
    collectors_list.vinyl_disk_data_size =
        utils.set_gauge('vinyl_disk_data_size', 'Amount of data stored in files',
            vinyl_stat.disk.data, nil, nil, {default = true})
    collectors_list.vinyl_disk_index_size =
        utils.set_gauge('vinyl_disk_index_size', 'Amount of index stored in files',
            vinyl_stat.disk.index, nil, nil, {default = true})

    collectors_list.vinyl_regulator_dump_bandwidth =
        utils.set_gauge('vinyl_regulator_dump_bandwidth', 'Estimated average rate at which dumps are done',
        vinyl_stat.regulator.dump_bandwidth, nil, nil, {default = true})
    collectors_list.vinyl_regulator_write_rate =
        utils.set_gauge('vinyl_regulator_write_rate', 'Average rate at which recent writes to disk are done',
        vinyl_stat.regulator.write_rate, nil, nil, {default = true})
    collectors_list.vinyl_regulator_rate_limit =
        utils.set_gauge('vinyl_regulator_rate_limit', 'Write rate limit',
            vinyl_stat.regulator.rate_limit, nil, nil, {default = true})
    collectors_list.vinyl_regulator_dump_watermark =
        utils.set_gauge('vinyl_regulator_dump_watermark', 'Point when dumping must occur',
        vinyl_stat.regulator.dump_watermark, nil, nil, {default = true})
    if vinyl_stat.regulator.blocked_writers ~= nil then
        collectors_list.vinyl_regulator_blocked_writers =
            utils.set_gauge('vinyl_regulator_blocked_writers', 'The number of fibers that are blocked waiting ' ..
            'for Vinyl level0 memory quota',
            vinyl_stat.regulator.blocked_writers, nil, nil, {default = true})
    end

    collectors_list.vinyl_tx_conflict =
        utils.set_gauge('vinyl_tx_conflict', 'Count of transaction conflicts',
            vinyl_stat.tx.conflict, nil, nil, {default = true})
    collectors_list.vinyl_tx_commit =
        utils.set_gauge('vinyl_tx_commit', 'Count of commits',
            vinyl_stat.tx.commit, nil, nil, {default = true})
    collectors_list.vinyl_tx_rollback =
        utils.set_gauge('vinyl_tx_rollback', 'Count of rollbacks',
            vinyl_stat.tx.rollback, nil, nil, {default = true})
    collectors_list.vinyl_tx_read_views =
        utils.set_gauge('vinyl_tx_read_views', 'Count of open read views',
            vinyl_stat.tx.read_views, nil, nil, {default = true})

    collectors_list.vinyl_memory_tuple_cache =
        utils.set_gauge('vinyl_memory_tuple_cache', 'Number of bytes that are being used for tuple',
            vinyl_stat.memory.tuple_cache, nil, nil, {default = true})
    collectors_list.vinyl_memory_level0 =
        utils.set_gauge('vinyl_memory_level0', 'Size of in-memory storage of an LSM tree',
            vinyl_stat.memory.level0, nil, nil, {default = true})
    collectors_list.vinyl_memory_page_index =
        utils.set_gauge('vinyl_memory_page_index', 'Size of page indexes',
            vinyl_stat.memory.page_index, nil, nil, {default = true})
    collectors_list.vinyl_memory_bloom_filter =
        utils.set_gauge('vinyl_memory_bloom_filter', 'Size of bloom filter',
            vinyl_stat.memory.bloom_filter, nil, nil, {default = true})

    collectors_list.vinyl_scheduler_tasks =
        utils.set_gauge('vinyl_scheduler_tasks', 'Vinyl tasks count',
            vinyl_stat.scheduler.tasks_inprogress, {status = 'inprogress'}, nil, {default = true})
    collectors_list.vinyl_scheduler_tasks =
        utils.set_gauge('vinyl_scheduler_tasks', 'Vinyl tasks count',
            vinyl_stat.scheduler.tasks_completed, {status = 'completed'}, nil, {default = true})
    collectors_list.vinyl_scheduler_tasks =
        utils.set_gauge('vinyl_scheduler_tasks', 'Vinyl tasks count',
            vinyl_stat.scheduler.tasks_failed, {status = 'failed'}, nil, {default = true})

    collectors_list.vinyl_scheduler_dump_time =
        utils.set_gauge('vinyl_scheduler_dump_time', 'Total time spent by all worker threads performing dump',
            vinyl_stat.scheduler.dump_time, nil, nil, {default = true})
    collectors_list.vinyl_scheduler_dump_total =
        utils.set_counter('vinyl_scheduler_dump_total', 'The count of completed dumps',
            vinyl_stat.scheduler.dump_count, nil, nil, {default = true})
end

return {
    update = update,
    list = collectors_list,
}
