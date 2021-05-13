require('strict').on()


local t = require('luatest')
local g = t.group('hotreload')

g.test_reload = function()
    box.cfg{}

    local metrics = require('metrics')

    local http_requests_total_counter = metrics.counter('http_requests_total')
    http_requests_total_counter:inc(1, {method = 'GET'})

    local http_requests_latency = metrics.summary(
        'http_requests_latency', 'HTTP requests total',
        {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}
    )
    http_requests_latency:observe(10)

    require('metrics.default_metrics.tarantool').enable()
    require('metrics.tarantool.luajit').enable()

    for k, mod in pairs(package.loaded) do
        if k:find('metrics') ~= nil then
            package.loaded[k] = nil
        end
    end

    require('metrics')
    
    t.assert_not_equals(require('metrics.default_metrics.tarantool').enable(), nil, "Metrics can't reload")
   require('metrics.tarantool.luajit').enable()
end
