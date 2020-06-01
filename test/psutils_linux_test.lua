#!/usr/bin/env tarantool


local t = require('luatest')
local g = t.group('psutils_linux')

local payload_dir = os.getenv('PWD') .. '/test/psutils_linux_test_payload'
local stat_file_path = payload_dir .. '/proc_stat'
local task_dir_path = payload_dir .. '/proc_self_task'

local psutils_linux
g.before_all(function()
    t.skip_if(require('ffi').os ~= 'Linux', 'Linux is the only supported platform')

    os.setenv('TEST_STAT_FILE_PATH', stat_file_path)
    os.setenv('TEST_TASK_PATH', task_dir_path)
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
