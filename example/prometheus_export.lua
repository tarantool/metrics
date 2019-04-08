#!/usr/bin/env tarantool
package.path = package.path .. ";../?.lua"

local log = require('log')

-- Create a Metrics Client
local metrics = require('metrics')

-- Init Prometheus Exporter
local httpd = require('http.server')
local http_handler = require('metrics.plugins.prometheus').collect_http
httpd.new('0.0.0.0', 8088)
    :route({path = '/metrics'}, function(...)
        log.info('---------------------')
        log.info('Handling GET /metrics')
        return http_handler(...)
    end)
    :start()

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
