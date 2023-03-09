#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('psutils_linux')

local fio = require('fio')
local fio_impl = table.deepcopy(fio)

local psutils_mock = require('test.psutils_linux_test_payload')

local psutils_linux = require('metrics.psutils.psutils_linux')

g.before_all(function()
    t.skip_if(jit.os ~= 'Linux', 'Linux is the only supported platform')

    fio.open = function(path, mode)
        return fio_impl.open(psutils_mock.files[path], mode)
    end
    fio.listdir = function(_)
        return fio_impl.listdir(psutils_mock.task_dir_path)
    end
end)

g.after_all(function()
    fio.open = fio_impl.open
    fio.listdir = fio_impl.listdir
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
