-- Linux is the only supported platform
if jit.os ~= 'Linux' then
    return { update = function() end }
end

local utils = require('metrics.utils')
local psutils = require('metrics.psutils.psutils_linux')

local collectors_list = {}

local instance_file = arg[0]
collectors_list.cpu_count = utils.set_gauge('cpu_count', 'The number of processors', psutils.get_cpu_count())
collectors_list.cpu_number = utils.set_gauge('cpu_number', 'The number of processors', psutils.get_cpu_count())

local function update_cpu_metrics()
    utils.set_gauge('cpu_total', 'Host CPU time', psutils.get_cpu_time())
    utils.set_gauge('cpu_time', 'Host CPU time', psutils.get_cpu_time())

    for _, thread_info in ipairs(psutils.get_process_cpu_time()) do
        collectors_list.cpu_thread = utils.set_gauge('cpu_thread', 'Tarantool thread cpu time', thread_info.utime, {
            kind = 'user',
            thread_name = thread_info.comm,
            thread_pid = thread_info.pid,
            file_name = instance_file,
        })

        collectors_list.cpu_thread = utils.set_gauge('cpu_thread', 'Tarantool thread cpu time', thread_info.stime, {
            kind = 'system',
            thread_name = thread_info.comm,
            thread_pid = thread_info.pid,
            file_name = instance_file,
        })
    end
end

return {
    update = update_cpu_metrics,
    list = collectors_list,
}
