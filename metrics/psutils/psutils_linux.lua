local fio = require('fio')
local string = require('string')
local ffi = require('ffi')
local log = require('log')

ffi.cdef[[
    int get_nprocs_conf(void);
]]

local function get_cpu_time()
    local cpu_stat_file = fio.open('/proc/stat', 'O_RDONLY')
    if cpu_stat_file == nil then
        log.error('/proc/stat open error')
        return nil
    end

    local stats_raw = cpu_stat_file:read(512)
    cpu_stat_file:close()
    if #stats_raw == 0 then
        log.error('/proc/stat read error')
        return nil
    end

    local stats = string.split(stats_raw, '\n')
    local cpu_times = string.split(stats[1])

    local sum = 0
    for i, cpu_time in ipairs(cpu_times) do
        if i > 1 then
            sum = sum + tonumber(cpu_time)
        end
    end

    return sum
end

local function parse_process_stat(path)
    local stat = fio.open(path, 'O_RDONLY')
    if stat == nil then
        print('stat open error')
        return nil
    end

    local s = stat:read(512)
    stat:close()

    local stats = string.split(s)
    return {
        pid = tonumber(stats[1]),
        comm = stats[2]:gsub('[()]', ''), -- strip spaces
        utime = tonumber(stats[14]),
        stime = tonumber(stats[15]),
    }
end

local function get_process_cpu_time()
    local threads = fio.listdir('/proc/self/task')
    local thread_time = {}
    for i, thread_pid in ipairs(threads) do
        thread_time[i] = parse_process_stat('/proc/self/task/' .. thread_pid .. '/stat')
    end

    return thread_time
end

return {
    get_cpu_time = get_cpu_time,
    get_process_cpu_time = get_process_cpu_time,
    get_cpu_count = ffi.C.get_nprocs_conf,
}
