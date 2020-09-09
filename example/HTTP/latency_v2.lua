#!/usr/bin/env tarantool
package.path = package.path .. ";../?.lua"

local json = require('json')
local fiber = require('fiber')
local metrics = require('metrics')
local log = require('log')
local http_middleware = metrics.http_middleware

-- Configure HTTP routing
local ip = '127.0.0.1'
local port = 12345
local httpd = require('http.server').new(ip, port) -- HTTP ver. 2.x.x
local router = require('http.router').new() -- HTTP ver. 2.x.x
local route = { path = '/path', method = 'POST' }

-- Set route handler
local handler = function(req)
    for _ = 1, 10 do
        fiber.sleep(0.1)
    end

    return { status = 200, body = req.body }
end
router:route(route, handler)

-- Configure summary latency collector
local collector = http_middleware.build_default_collector(
    'summary', 'path_latency',
    'My collector for /path requests latency'
)

-- Set router summary latency collection middleware
router:use(http_middleware.v2(collector), { name = 'latency_instrumentation' })

-- Start HTTP routing using configured router
httpd:set_router(router)
httpd:start()

-- Set HTTP client, make some request
local http_client = require("http.client").new() -- HTTP ver. 2.x.x
http_client:request(route.method, 'http://' .. ip .. ':' .. port .. route.path, json.encode({ body = 'text' }))

-- Collect the metrics
log.info(metrics.collect())
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
  value: 1.0240110000595
   metric_name: path_latency_sum

 - label_pairs:
     path: /path
     method: POST
     status: 200
     quantile: 0.5
   timestamp: 1588951616500768
   value: 1.0240110000595
   metric_name: path_latency

 - label_pairs:
     path: /path
     method: POST
     status: 200
     quantile: 0.9
   timestamp: 1588951616500768
   value: 1.0240110000595
   metric_name: path_latency

 - label_pairs:
     path: /path
     method: POST
     status: 200
     quantile: 0.99
   timestamp: 1588951616500768
   value: 1.0240110000595
   metric_name: path_latency


--]]

-- Exit event loop
os.exit()
