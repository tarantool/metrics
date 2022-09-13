require('strict').on()

local fio = require('fio')

local t = require('luatest')
local g = t.group('highload')

g.test_eventloop = function()
    local tmpdir = fio.tempdir()
    if type(box.cfg) == 'function' then
        box.cfg {
            wal_dir = tmpdir,
            memtx_dir = tmpdir,
        }
    end

    local metrics = require('metrics')
    local fiber = require('fiber')
    local clock = require('clock')
    local utils = require('test.utils')

    local function monitor(collector)
        local time_before
        while true do
            time_before = clock.monotonic()
            fiber.yield()
            collector:observe(clock.monotonic() - time_before)
        end
    end

    metrics.set_global_labels({ alias = 'my_instance' })

    local collector = metrics.summary('tnt_fiber_event_loop', 'event loop time',
        { [0.5] = 0.01, [0.9] = 0.01, [0.99] = 0.01, })
    fiber.create(function() monitor(collector) end)

    for _ = 1, 20 do
        fiber.sleep(0.1)
        local observations = metrics.collect()
        local obs_summary = utils.find_obs('tnt_fiber_event_loop', { alias = 'my_instance', quantile = 0.99 }, observations)
        t.assert_not_inf(obs_summary.value)
    end

end
