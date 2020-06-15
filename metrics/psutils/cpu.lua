-- Linux is the only supported platform
if jit.os ~= 'Linux' then
    return { update = function() end }
end

local utils = require('metrics.utils')
local psutils = require('metrics.psutils.psutils_linux')

local instance_file = arg[0]
utils.set_gauge('cpu_count', 'The number of processors', psutils.get_cpu_count())

local function update_cpu_metrics()
    utils.set_gauge('cpu_total', 'Host CPU time', psutils.get_cpu_time())

    for _, thread_info in ipairs(psutils.get_process_cpu_time()) do
        utils.set_gauge('cpu_thread', 'Tarantool thread cpu time', thread_info.utime, {
            kind = 'user',
            thread_name = thread_info.comm,
            thread_pid = thread_info.pid,
            file_name = instance_file,
        })

        utils.set_gauge('cpu_thread', 'Tarantool thread cpu time', thread_info.stime, {
            kind = 'system',
            thread_name = thread_info.comm,
            thread_pid = thread_info.pid,
            file_name = instance_file,
        })
    end
end

return {
    update = update_cpu_metrics,
}
