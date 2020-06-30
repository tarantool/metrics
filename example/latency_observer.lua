#!/usr/bin/env tarantool
package.path = package.path .. ";../?.lua"

local fiber = require('fiber')
local metrics = require('metrics')

box.cfg{
    listen = 3302
}

box.schema.user.grant(
    'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
)

-- Measured function
local function worker(time)
    fiber.sleep(time)
    return true
end

-- Create histogram
local latency_hist = metrics.histogram('func_call_latency', 'Help message', {0.1, 0.5, 0.9})

-- Wrapper with observe_latency
local function wrapper_worker(...)
    return latency_hist:observe_latency(
        -- Dynamic label pairs, depends on success
        function(ok, _, _) return {ok = tostring(ok)} end,
        -- Wrapped function
        worker,
        -- Function args
        ...
    )
end

rawset(_G, 'api_function', wrapper_worker)
