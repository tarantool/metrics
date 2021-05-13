require('strict').on()


local t = require('luatest')
local g = t.group('hotreload')

g.test_reload = function()
    box.cfg{}

    local metrics = require('metrics')
    -- create a counter
    local http_requests_total_counter = metrics.counter('http_requests_total')

    http_requests_total_counter:inc(1, {method = 'GET'})

    local cpu_usage_gauge = metrics.gauge('cpu_usage', 'CPU usage')

    metrics.register_callback(function()
        local current_cpu_usage = 42
        cpu_usage_gauge:set(current_cpu_usage, {app = 'tarantool'})
    end)

    -- create a histogram
    local http_requests_latency_hist = metrics.histogram(
        'http_requests_latency', 'HTTP requests total', {2, 4, 6})

    -- somewhere in the HTTP requests middleware:
    local latency = math.random(1, 10)
    http_requests_latency_hist:observe(latency)

    -- create a summary
    local http_requests_latency = metrics.summary(
        'http_requests_latency', 'HTTP requests total',
        {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}
    )

    -- somewhere in the HTTP requests middleware:
    local latency = math.random(1, 10)
    http_requests_latency:observe(latency)

    require('metrics.default_metrics.tarantool').enable()
    require('metrics.tarantool.luajit').enable()

    for k, mod in pairs(package.loaded) do
        if k:find('metrics') ~= nil then
            package.loaded[k] = nil
        end
    end

    require('metrics')
    
    t.assert_not_equals(require('metrics.default_metrics.tarantool').enable(), nil, "Metrics can't reload")
end
