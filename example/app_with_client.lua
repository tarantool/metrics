#!/usr/bin/env tarantool
package.path = package.path .. ";../?.lua"

-- Create a Metrics Client
local client = require('metrics_client').new()

-------------------------- Create Collectors ---------------------------

-- Create Counter "total_http_requests"
local total_http_requests = client:counter('total_http_requests')

-- Create Gauge "cpu_usage"
local cpu_usage = client:gauge('cpu_usage')

-- Create Histogram "total_http_requests" with buckets {2, 4, 6}
-- NOTE: no name clashing here, since on the Server there will be created 3 separate Counters with names:
--   total_http_request_count,
--   total_http_request_sum,
--   total_http_request_buckets
local total_http_requests_hist = client:histogram('total_http_requests', nil, {2, 4, 6})

---------------------------- Use Collectors ----------------------------

do -- Counter usage
  total_http_requests:inc(1)                    -- creates observation with label set "" (empty label set) and increments it by 1
  total_http_requests:inc(2, {method = 'POST'}) -- creates observation with label set "method -> HTTP" and increments it by 2
  total_http_requests:inc(3, {method = 'GET'})  -- creates observation with label set "method -> GET" and increments it by 3
  total_http_requests:inc(1, {method = 'GET'})  -- increments existing observation with label set "method -> GET" and increments it by 1
  total_http_requests:inc(2)                    -- increments existing observation with label set "" (empty label set) and increments it by 2
end
-- By now there will be 3 different observations stored in this Counter

do -- Gauge usage
  cpu_usage:set(0.55) -- creates observation with label set "" (empty label set) and set it to 0.55
  cpu_usage:inc(0.01) -- increments already existing observation by 0.01
  cpu_usage:inc(0.02, {application = 'tarantool'}) -- creates observation with label set "application -> tarantool" and increments it to 0.02
  cpu_usage:set(0.7, {application = 'tarantool'}) -- sets existing observation with label set "application -> tarantool"
end
-- By now there will be 2 different observations stored in this Gauge

do -- Histogram usage
  total_http_requests_hist:observe(1)
  total_http_requests_hist:observe(3)
end
