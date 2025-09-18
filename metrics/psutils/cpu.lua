-- Linux is the only supported platform
if jit.os ~= 'Linux' then
    return { update = function() end }
end

local utils = require('metrics.utils')
local psutils = require('metrics.psutils.psutils_linux')

local collectors_list = {}

local instance_file = arg[0]

local threads = {}

local function update_cpu_metrics()
    collectors_list.cpu_number = utils.set_gauge('cpu_number', 'The number of processors',
        psutils.get_cpu_count(), nil, nil, {default = true})

    collectors_list.cpu_time = utils.set_gauge('cpu_time', 'Host CPU time',
        psutils.get_cpu_time(), nil, nil, {default = true})

    local new_threads = {}
    for _, thread_info in ipairs(psutils.get_process_cpu_time()) do
        local labels = {
            thread_name = thread_info.comm,
            thread_pid = thread_info.pid,
            file_name = instance_file,
        }

        local utime_labels = table.copy(labels)
        utime_labels.kind = 'user'
        collectors_list.cpu_thread = utils.set_gauge('cpu_thread', 'Tarantool thread cpu time',
            thread_info.utime, utime_labels, nil, {default = true})

        local stime_labels = table.copy(labels)
        stime_labels.kind = 'system'
        collectors_list.cpu_thread = utils.set_gauge('cpu_thread', 'Tarantool thread cpu time',
            thread_info.stime, stime_labels, nil, {default = true})

        threads[thread_info.pid] = nil
        new_threads[thread_info.pid] = labels
    end

    for _, thread_info in pairs(threads) do
        thread_info.kind = 'user'
        collectors_list.cpu_thread:remove(thread_info)

        thread_info.kind = 'system'
        collectors_list.cpu_thread:remove(thread_info)
    end
    threads = new_threads
end

local function clear_cpu_metrics()
    utils.delete_collectors(collectors_list)
end

return {
    update = update_cpu_metrics,
    list = collectors_list,
    clear = clear_cpu_metrics,
}
