require('strict').on()

local t = require('luatest')
local g = t.group('highload')
local utils = require('test.utils')

g.before_all(utils.create_server)

g.after_all(utils.drop_server)

g.test_eventloop = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local fiber = require('fiber')
        local clock = require('clock')
        local utils = require('test.utils') -- luacheck: ignore 431

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
        local fiber_object = fiber.create(function() monitor(collector) end)

        for _ = 1, 10 do
            fiber.sleep(0.1)
            local observations = metrics.collect()

            local obs_summary = utils.find_obs('tnt_fiber_event_loop',
                { alias = 'my_instance', quantile = 0.99 }, observations)

            t.assert_not_inf(obs_summary.value)
        end

        fiber.kill(fiber_object:id())
    end)
end
