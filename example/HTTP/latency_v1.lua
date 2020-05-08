#!/usr/bin/env tarantool
package.path = package.path .. ";../?.lua"

local json = require('json')
local fiber = require('fiber')
local metrics = require('metrics')
local http_middleware = metrics.http_middleware

-- Configure HTTP routing
local ip = '127.0.0.1'
local port = 12345
local httpd = require('http.server').new(ip, port) -- HTTP ver. 1.x.x
local route = { path = '/path', method = 'POST' }

-- Route handler
local handler = function(req)
    for _ = 1, 10 do
        fiber.sleep(0.1)
    end

    return { status = 200, body = req.body }
end

-- Configure average latency collector
local collector = http_middleware.build_default_collector(
    'average', 'path_latency',
    'My collector for /path requests latency'
)

-- Set route handler with average latency collection
httpd:route(route, http_middleware.v1(handler, collector))
-- Start HTTP routing
httpd:start()

-- Set HTTP client, make some request
local http_client = require("http.client") -- HTTP ver. 1.x.x
http_client.post('http://' .. ip .. ':' .. port .. route.path, json.encode({ body = 'text' }))

-- Collect the metrics
metrics.collect()
--[[

- label_pairs:
    path: /path
    method: POST
    status: 200
  timestamp: 1588951616500768
  value: 1
  metric_name: path_latency_count

- label_pairs:
    path: /path
    method: POST
    status: 200
  timestamp: 1588951616500768
  value: 1.0038734949776
  metric_name: path_latency_avg

--]]

-- Exit event loop
os.exit()
