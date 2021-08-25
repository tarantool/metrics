local clock = require('clock')
local fiber = require('fiber')
local metrics = require('metrics')

local collectors_list = {}

local function monitor()
    fiber.self():name("tx_speed")

    local max = -math.huge

    while true do
        local start = clock.monotonic64()
        fiber.yield()
        local diff = clock.monotonic64() - start
        -- measure max time between in case
        -- if maximum diff was between two metrics.collect() calls
        if diff > max then
            max = diff
        end
        local collector = metrics.registry:find('gauge', 'tnt_tx_loop_delay')
        if not collector then
            -- if collector was removed from registry
            rawset(_G, '__metrics_tx_speed', nil)
            return
        end
        collector:set(tonumber(diff)/10^6, {time = 'current'})
        collector:set(tonumber(max)/10^6, {time = 'max'})
    end
end


local function update()
    collectors_list.tnt_tx_loop_delay = metrics.gauge('tnt_tx_loop_delay', 'Tarantool tx thread event loop delay')
    if rawget(_G, '__metrics_tx_speed') == nil then
        rawset(_G, '__metrics_tx_speed', fiber.create(monitor))
    end
end

return {
    update = update,
    list = collectors_list,
}
