local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

local fun = require('fun')
local metrics = require('metrics')
local http_middleware = metrics.http_middleware

g.before_each(function()
    metrics.clear()
    http_middleware.set_default_collector(nil)
end)

g.after_all(function()
    http_middleware.set_default_collector(nil)
end)

local function merge(...)
    return fun.chain(...):tomap()
end

local function stub_observer(observe)
    return {
        observe = observe,
        observe_latency = require('metrics.collectors.shared').observe_latency,
    }
end

local route = {path = '/some/path', method = 'POST'}

g.test_build_default_collector_histogram = function()
    local collector = http_middleware.build_default_collector()
    t.assert_equals(collector.kind, 'histogram')
    t.assert_equals(collector.name, 'http_server_request_latency')
    t.assert_equals(collector.help, 'HTTP Server Request Latency')
    t.assert_equals(collector.buckets, http_middleware.DEFAULT_HISTOGRAM_BUCKETS)
    collector = http_middleware.build_default_collector('histogram', 'custom_name', 'custom_help')
    t.assert_equals(collector.kind, 'histogram')
    t.assert_equals(collector.name, 'custom_name')
    t.assert_equals(collector.help, 'custom_help')
    t.assert_equals(collector.buckets, http_middleware.DEFAULT_HISTOGRAM_BUCKETS)
end

g.test_build_default_collector_summary = function()
    local collector = http_middleware.build_default_collector('summary')
    t.assert_equals(collector.kind, 'summary')
    t.assert_equals(collector.name, 'http_server_request_latency')
    t.assert_equals(collector.help, 'HTTP Server Request Latency')
    collector = http_middleware.build_default_collector('summary', 'custom_name', 'custom_help')
    t.assert_equals(collector.kind, 'summary')
    t.assert_equals(collector.name, 'custom_name')
    t.assert_equals(collector.help, 'custom_help')
end

g.test_build_default_collector_invalid = function()
    t.assert_error_msg_contains('Unknown collector type_name: some_type', function()
        http_middleware.build_default_collector('some_type')
    end)
end

g.test_build_default_collector_with_same_name = function()
    http_middleware.build_default_collector('histogram', 'name1', 'help1')
    t.assert_error_msg_contains('Already registered', function()
        http_middleware.build_default_collector('histogram', 'name1', 'help2')
    end)
    http_middleware.build_default_collector('histogram', 'name2', 'help2')
end

g.test_observe = function()
    local result = {value = 'result'}
    local observed
    local function subject()
        return http_middleware.observe(
            stub_observer(function(_, ...) observed = {...} return {'observer result'} end),
            merge(route, {other = 'value'}),
            function(arg1, arg2)
                t.assert_equals({arg1, arg2}, {'value1', 'value2'})
                return result
            end,
            'value1',
            'value2'
        )
    end

    t.assert_is(subject(), result)
    t.assert_type(observed[1], 'number')
    t.assert_equals(observed[2], merge(route, {status = 200}))

    result.status = 400
    t.assert_is(subject(), result)
    t.assert_equals(observed[2], merge(route, {status = 400}))
end

g.test_observe_handler_failure = function()
    local err = {custom = 'error'}
    local observed
    t.assert_equals(t.assert_error(function()
        http_middleware.observe(
            stub_observer(function(_, ...) observed = {...} return {'observer result'} end),
            route,
            function() error(err) end
        )
    end), err)
    t.assert_type(observed[1], 'number')
    t.assert_equals(observed[2], merge(route, {status = 500}))
end

g.test_observe_observer_failure = function()
    local result = {value = 'result'}
    local capture = require('luatest.capture'):new()
    capture:wrap(true, function()
        t.assert_is(http_middleware.observe(
            stub_observer(function() error({custom = 'error'}) end),
            route,
            function() return result end
        ), result)
    end)
    t.assert_str_contains(capture:flush().stderr, 'Saving metrics failed')
end

g.test_v1_middleware = function()
    local request = {endpoint = table.copy(route)}
    local result = {value = 'result'}
    local observed
    local observer = stub_observer(function(_, ...) observed = {...} end)
    local handler = function(arg)
        t.assert_is(arg, request)
        return result
    end

    t.assert_is(http_middleware.v1(handler, observer)(request), result)
    t.assert_equals(metrics.collect(), {})
    t.assert_type(observed[1], 'number')
    t.assert_equals(observed[2], merge(route, {status = 200}))

    t.assert_is(http_middleware.v1(handler)(request), result)
    t.assert_is(http_middleware.v1(handler)(request), result)
    local observations = metrics.collect()
    t.assert_equals(
        utils.find_obs('http_server_request_latency_count', merge(route, {status = 200}), observations).value,
        2
    )
    t.assert_type(
        utils.find_obs('http_server_request_latency_sum', merge(route, {status = 200}), observations).value,
        'number'
    )
end

g.test_v2_middleware = function()
    local httpd = require('http.server').new('127.0.0.1', 12345)
    t.skip_if(httpd.set_router == nil, 'Skip http 2.x test')
    local router = require('http.router').new()
    router:route(route, function() return {body = 'test-response', status = 200} end)
    router:use(http_middleware.v2(), {name = 'http_instrumentation'})
    httpd:set_router(router)
    httpd:start()
    local client = require('http.client').new()
    local response = client:request(route.method, 'http://127.0.0.1:12345' .. route.path)
    httpd:stop()
    t.assert_equals(response.body, 'test-response')
    local observations = metrics.collect()
    t.assert_equals(
        utils.find_obs('http_server_request_latency_count', merge(route, {status = 200}), observations).value,
        1
    )
    t.assert_type(
        utils.find_obs('http_server_request_latency_sum', merge(route, {status = 200}), observations).value,
        'number'
    )
end
