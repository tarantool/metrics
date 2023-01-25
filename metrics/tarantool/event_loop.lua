local utils = require('metrics.utils')
local fiber = require('fiber')
local clock = require('clock')

local collectors_list = {}

local ev_now_64 = function() return 1e3*fiber.time64() end

local function evloop_time()
	fiber.sleep(0) -- setups watcher to the start of next ev_run

	local e0, w0 = ev_now_64(), clock.time64()
	fiber.sleep(0) -- rotates single loop
	local e1, w1 = ev_now_64(), clock.time64()

	-- e0 <= w0 <= e1 <= w1 (if ntp is ok)
    local ev_loop_time, ev_prolog, ev_epilog
    if e1 <= w1 then
        -- lag from the start of the loop till current fiber (must be as little as possible)
        ev_prolog = w1-e1
    else
        ev_prolog = 0
    end
    if w0 <= e1 then
        -- the epilog of previous ev_once
        ev_epilog = e1-w0
    else
        ev_epilog = 0
    end

    if e0 < e1 then
        -- diff between 2 neighbour ev_once's
        ev_loop_time = e1-e0
    else
        ev_loop_time = 0
    end

    -- convert to double to get seconds precision
	return tonumber(ev_loop_time/1e3)/1e3, tonumber(ev_prolog/1e3)/1e3, tonumber(ev_epilog/1e3)/1e3
end


local function update_info_metrics()
    local ev_once_time, ev_prolog, ev_epilog = evloop_time()
    collectors_list.ev_loop_time = utils.set_gauge('ev_loop_time', 'Event loop time (ms)',
        ev_once_time, nil, nil, {default = true})
    collectors_list.ev_prolog_time = utils.set_gauge('ev_loop_prolog_time', 'Event loop prolog time (ms)',
        ev_prolog, nil, nil, {default = true})
    collectors_list.ev_epilog_time = utils.set_gauge('ev_loop_epilog_time', 'Event loop epilog time (ms)',
        ev_epilog, nil, nil, {default = true})
end

return {
    update = update_info_metrics,
    list = collectors_list,
}
