#!/usr/bin/env tarantool
local fio = require('fio')
local prometheus = require('metrics.plugins.prometheus')
local metrics = require('metrics')

local counter = metrics.counter('counter_total', 'help text')
local gauge = metrics.gauge('gauge', 'help text')
local histogram = metrics.histogram('histogran', 'help text', nil)
local summary = metrics.summary('summary', 'help text', {[0.5] = 0.01, [0.9] = 0.01, [0.99] = 0.01})
for i = 1, 10^3 do
    summary:observe(i)
    histogram:observe(i)
end
counter:inc(1)
gauge:set(1)

local fh = fio.open('prometheus-input', {'O_RDWR', 'O_CREAT'}, tonumber('644',8))
fh:write(prometheus.collect_http().body)
fh:close()

os.exit()
