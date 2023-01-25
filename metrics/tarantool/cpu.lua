local ffi = require('ffi')
local utils = require('metrics.utils')

local collectors_list = {}

if not pcall(ffi.typeof, "struct timeval") then
    if ffi.os == 'OSX' then
        ffi.cdef[[
            typedef int32_t suseconds_t;
            struct timeval {
                long        tv_sec;     /* seconds */
                suseconds_t tv_usec;    /* microseconds */
            };
        ]]
    else
        ffi.cdef[[
            struct timeval {
                long tv_sec;     /* seconds */
                long tv_usec;    /* microseconds */
            };
        ]]
    end
end

if not pcall(ffi.typeof, "struct rusage") then
    ffi.cdef[[
        struct rusage {
            struct timeval ru_utime; /* user CPU time used */
            struct timeval ru_stime; /* system CPU time used */
            long   ru_maxrss;        /* maximum resident set size */
            long   ru_ixrss;         /* integral shared memory size */
            long   ru_idrss;         /* integral unshared data size */
            long   ru_isrss;         /* integral unshared stack size */
            long   ru_minflt;        /* page reclaims (soft page faults) */
            long   ru_majflt;        /* page faults (hard page faults) */
            long   ru_nswap;         /* swaps */
            long   ru_inblock;       /* block input operations */
            long   ru_oublock;       /* block output operations */
            long   ru_msgsnd;        /* IPC messages sent */
            long   ru_msgrcv;        /* IPC messages received */
            long   ru_nsignals;      /* signals received */
            long   ru_nvcsw;         /* voluntary context switches */
            long   ru_nivcsw;        /* involuntary context switches */
        };
        int getrusage(int who, struct rusage *usage);
        int gettimeofday(struct timeval *tv, struct timezone *tz);
    ]]
end

local RUSAGE_SELF = 0

local shared_rusage = ffi.new("struct rusage[1]")

local function ss_get_rusage()
    if ffi.C.getrusage(RUSAGE_SELF, shared_rusage) < 0 then
        return nil
    end

    local ru_utime = tonumber(shared_rusage[0].ru_utime.tv_sec) +
                     (tonumber(shared_rusage[0].ru_utime.tv_usec) / 1000000)
    local ru_stime = tonumber(shared_rusage[0].ru_stime.tv_sec) +
                     (tonumber(shared_rusage[0].ru_stime.tv_usec) / 1000000)

    return {
      ru_utime = ru_utime,
      ru_stime = ru_stime,
    }
end

local function update_info_metrics()
    local cpu_time = ss_get_rusage()
    if cpu_time then
        collectors_list.cpu_user_time = utils.set_gauge('cpu_user_time', 'CPU user time usage',
            cpu_time.ru_utime, nil, nil, {default = true})
        collectors_list.cpu_system_time = utils.set_gauge('cpu_system_time', 'CPU system time usage',
            cpu_time.ru_stime, nil, nil, {default = true})
    end
end

return {
    update = update_info_metrics,
    list = collectors_list,
}
