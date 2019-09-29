#!/usr/bin/env tarantool
package.path = package.path .. ";../?.lua"

-- Create a Metrics Client
local metrics = require('metrics')

-- Init InfluxDB Exporter
local influxdb = require('metrics.plugins.influxdb')
influxdb.init{
    host = '127.0.0.1',
    port = 8086,
    db_name = 'tarantool',
    send_interval = 1,
    field_name = 'value',
} -- Now started background worker which will collect all values of
  -- metrics.{counter,gauge,histogram} created below once per second and send them to
  -- 127.0.0.1:8086 in influxDB line protocol format

-- Create Collectors
local http_requests_total_counter = metrics.counter('http_requests_total')
local cpu_usage_gauge = metrics.gauge('cpu_usage')
local http_requests_total_hist = metrics.histogram('http_requests_total', nil, {2, 4, 6})

-- Use Collectors
http_requests_total_counter:inc(1, {method = 'GET'})
cpu_usage_gauge:set(0.24, {app = 'tarantool'})
http_requests_total_hist:observe(1)

-- Register Callbacks
metrics.register_callback(function()
    cpu_usage_gauge:set(math.random(), {app = 'tarantool'})
end)
metrics.register_callback(function()
    http_requests_total_counter:inc(1, {method = 'POST'})
    http_requests_total_hist:observe(math.random(1, 10))
end) -- this functions will be automatically called before every metrics.collect()
