#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('psutils_linux')

local fio = require('fio')

local payload_dir = os.getenv('PWD') .. '/test/psutils_linux_test_payload'
local stat_file_path = payload_dir .. '/proc_stat'
local task_dir_path = payload_dir .. '/proc_self_task'

local psutils_linux
g.before_all(function()
    t.skip_if(jit.os ~= 'Linux', 'Linux is the only supported platform')

    local task_files = {
        ['/proc/stat'] = stat_file_path,
        ['/proc/self/task/1/stat'] = task_dir_path .. '/1/stat',
        ['/proc/self/task/12/stat'] = task_dir_path .. '/12/stat',
        ['/proc/self/task/13/stat'] = task_dir_path .. '/13/stat',
        ['/proc/self/task/14/stat'] = task_dir_path .. '/14/stat',
    }
    package.loaded['fio'] = {
        open = function(path, mode)
            return fio.open(task_files[path], mode)
        end,
        listdir = function(_)
            return fio.listdir(task_dir_path)
        end,
    }

    psutils_linux = require('metrics.psutils.psutils_linux')
end)

g.test_get_cpu_time = function()
    local expected = 138445
    t.assert_equals(psutils_linux.get_cpu_time(), expected)
end

g.test_get_process_cpu_time = function()
    local expected = {
        {pid = 1, comm = 'tarantool', utime = 468, stime = 171},
        {pid = 12, comm = 'coio', utime = 0, stime = 0},
        {pid = 13, comm = 'iproto', utime = 118, stime = 534},
        {pid = 14, comm = 'wal', utime = 0, stime = 0},
    }
    t.assert_items_equals(psutils_linux.get_process_cpu_time(), expected)
end

g.test_get_cpu_count = function()
    t.assert_gt(psutils_linux.get_cpu_count(), 0)
end
