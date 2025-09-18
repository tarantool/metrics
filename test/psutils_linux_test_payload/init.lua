local payload_dir = debug.sourcedir()
local stat_file_path = payload_dir .. '/proc_stat'
local task_dir_path = payload_dir .. '/proc_self_task'

return {
    files = {
        ['/proc/stat'] = stat_file_path,
        ['/proc/self/task/1/stat'] = task_dir_path .. '/1/stat',
        ['/proc/self/task/12/stat'] = task_dir_path .. '/12/stat',
        ['/proc/self/task/13/stat'] = task_dir_path .. '/13/stat',
        ['/proc/self/task/14/stat'] = task_dir_path .. '/14/stat',
    },
    task_dir_path = task_dir_path,
}
