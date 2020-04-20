local clock = require('clock')
local log = require('log')

local export = {}

export.DEFAULT_HISTOGRAM_BUCKETS = {
    0.001,  0.0025, 0.005,  0.0075,
    0.01,   0.025,  0.05,   0.075,
    0.1,    0.25,   0.5,    0.75,
    1.0,    2.5,    5.0,    7.5,
    10.0,
}

--- Build default histogram collector
--
-- @string[opt='histogram'] type_name `histogram` or `average`
-- @string[opt='http_server_requests'] name
-- @string[opt='HTTP Server Requests'] help
-- @return collector
function export.build_default_collector(type_name, name, help)
    type_name = type_name or 'histogram'
    name = name or 'http_server_request_latency'
    help = help or 'HTTP Server Request Latency'
    local extra = {}
    if type_name == 'histogram' then
        extra = {export.DEFAULT_HISTOGRAM_BUCKETS}
    elseif type_name ~= 'average' then
        error('Unknown collector type_name: ' .. tostring(type_name))
    end
    local class = require('metrics.collectors.' .. type_name)
    return require('metrics').registry:find_or_create(class, name, help, unpack(extra))
end

function export.get_default_collector()
    if not export.default_collector then
        export.default_collector = export.build_default_collector()
    end
    return export.default_collector
end

--- Set default collector for all middlewares
--
-- @tab collector object with `:collect` method.
function export.set_default_collector(collector)
    export.default_collector = collector
end

--- Build collector and set it as default
--
-- @see build_default_collector
function export.configure_default_collector(...)
    export.set_default_collector(export.build_default_collector(...))
end

--- Measure latency and invoke collector with labels from given route
--
-- @tab collector
-- @tab route
-- @string route.path
-- @string route.method
-- ... arguments for pcall to instrument
function export.observe(collector, route, ...)
    local start_time = clock.monotonic()
    local ok, result = pcall(...)
    local latency = clock.monotonic() - start_time

    xpcall(function()
        local status = (not ok and 500) or result.status or 200
        collector:observe(latency, {path = route.path, method = route.method, status = status})
    end, function(err)
        log.error(debug.traceback('Saving metrics failed: ' .. tostring(err)))
    end)

    if not ok then
        error(result)
    end
    return result
end

--- Apply instrumentation middleware for http request handler
--
-- @func handler original
-- @func[opt] collector custom histogram-like collector
-- @return new handler
-- @usage httpd:route({method = 'GET', path = '/...'}, http_middleware.v1(request_handler))
function export.v1(handler, collector)
    collector = collector or export.get_default_collector()
    return function(req)
        return export.observe(collector, req.endpoint, handler, req)
    end
end

--- Build middleware for http
--
-- @func[opt] collector custom histogram-like collector
-- @return middleware
-- @usage router:use(http_middleware.v2(), {name = 'http_instrumentation'})
function export.v2(collector)
    collector = collector or export.get_default_collector()
    local tsgi = require('http.tsgi')
    return function(env)
        return export.observe(collector, env[tsgi.KEY_ROUTE].endpoint, tsgi.next, env)
    end
end

return export
