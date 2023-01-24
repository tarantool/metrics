#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('psutils_linux_clean_info')
local utils = require('test.utils')
local metrics = require('metrics')
local fiber = require('fiber')
local fio = require('fio')
local psutils_linux = require('metrics.psutils.psutils_linux')
local cpu = require('metrics.psutils.cpu')

g.before_all(function()
    t.skip_if(jit.os ~= 'Linux', 'Linux is the only supported platform')
    utils.init()
end)

g.after_each(function()
    metrics.clear()
end)

g.test_clean_thread_info = function()
    box.cfg{worker_pool_threads = 100}

    for _ = 1, 1000 do
        fiber.new(function() fio.stat(arg[-1]) end)
    end
    fiber.sleep(0.1)

    cpu.update()
    local list1 = psutils_linux.get_process_cpu_time()
    local observations1 = metrics.collect()
    local coio_count1 = 0
    for _, thread_info in ipairs(list1) do
        if thread_info.comm == 'coio' then
            coio_count1 = coio_count1 + 1
        end
    end

    box.cfg{worker_pool_threads = 1}
    fiber.sleep(0.1)

    cpu.update()
    local list2 = psutils_linux.get_process_cpu_time()
    local observations2 = metrics.collect()
    local coio_count2 = 0
    for _, thread_info in ipairs(list2) do
        if thread_info.comm == 'coio' then
            coio_count2 = coio_count2 + 1
        end
    end

    t.assert_gt(#list1, #list2)
    t.assert_gt(#observations1, #observations2)
    t.assert_gt(coio_count1, coio_count2)
    t.assert_equals(#observations1 - #observations2, 2 * (coio_count1 - coio_count2))
end
