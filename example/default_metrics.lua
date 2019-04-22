#!/usr/bin/env tarantool
package.path = package.path .. ";../?.lua"

local log = require('log')

-- Create a Metrics Client
local metrics = require('metrics')

-- Enable default metrics collections

metrics.enable_default_metrics();


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

box.cfg{
    listen = 3302
}
