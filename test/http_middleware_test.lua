local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

g.before_all(function(cg)
    utils.create_server(cg)

    cg.server:exec(function()
        local fun = require('fun')

        local function merge(...)
            return fun.chain(...):tomap()
        end
        rawset(_G, 'merge', merge)

        local function stub_observer(observe)
            return {
                observe = observe,
                observe_latency = require('metrics.collectors.shared').observe_latency,
            }
        end
        rawset(_G, 'stub_observer', stub_observer)

        local route = {path = '/some/path', method = 'POST'}
        rawset(_G, 'route', route)
    end)
end)
g.after_all(utils.drop_server)

g.before_each(function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local http_middleware = metrics.http_middleware

        metrics.clear()
        http_middleware.set_default_collector(nil)
    end)
end)


g.test_build_default_collector_histogram = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

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
    end)
end

g.test_build_default_collector_summary = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

        local collector = http_middleware.build_default_collector('summary')
        t.assert_equals(collector.kind, 'summary')
        t.assert_equals(collector.name, 'http_server_request_latency')
        t.assert_equals(collector.help, 'HTTP Server Request Latency')
        collector = http_middleware.build_default_collector('summary', 'custom_name', 'custom_help')
        t.assert_equals(collector.kind, 'summary')
        t.assert_equals(collector.name, 'custom_name')
        t.assert_equals(collector.help, 'custom_help')
    end)
end

g.test_build_default_collector_invalid = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

        t.assert_error_msg_contains('Unknown collector type_name: some_type', function()
            http_middleware.build_default_collector('some_type')
        end)
    end)
end

g.test_build_default_collector_with_same_name = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

        http_middleware.build_default_collector('histogram', 'name1', 'help1')
        t.assert_error_msg_contains('Already registered', function()
            http_middleware.build_default_collector('histogram', 'name1', 'help2')
        end)
        http_middleware.build_default_collector('histogram', 'name2', 'help2')
    end)
end

g.test_observe = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

        local merge = rawget(_G, 'merge')
        local stub_observer = rawget(_G, 'stub_observer')
        local route = rawget(_G, 'route')

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
    end)
end

g.test_observe_handler_failure = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

        local merge = rawget(_G, 'merge')
        local stub_observer = rawget(_G, 'stub_observer')
        local route = rawget(_G, 'route')

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
    end)
end

g.test_observe_observer_failure = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

        local stub_observer = rawget(_G, 'stub_observer')
        local route = rawget(_G, 'route')

        local result = {value = 'result'}
        t.assert_is(http_middleware.observe(
            stub_observer(function() error({custom = 'error'}) end),
            route,
            function() return result end
        ), result)
    end)

    t.assert(cg.server:grep_log('Saving metrics failed'))
end

g.test_v1_middleware = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local http_middleware = metrics.http_middleware
        local utils = require('test.utils') -- luacheck: ignore

        local merge = rawget(_G, 'merge')
        local stub_observer = rawget(_G, 'stub_observer')
        local route = rawget(_G, 'route')

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
    end)
end

g.test_v1_wrong_handler = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local http_middleware = metrics.http_middleware

        local stub_observer = rawget(_G, 'stub_observer')
        local route = rawget(_G, 'route')

        local request = {endpoint = table.copy(route)}

        local observer = stub_observer(function() end)
        local handler = function()
            -- we forget to return result!
            -- return result
        end
        t.assert_error_msg_contains(
            'incorrect http handler for POST /some/path: expecting return response object',
            http_middleware.v1(handler, observer), request
        )
    end)
end

g.test_v1_handler_raise_an_error = function(cg)
    cg.server:exec(function()
        local http_middleware = require('metrics').http_middleware

        local stub_observer = rawget(_G, 'stub_observer')
        local route = rawget(_G, 'route')

        local request = {endpoint = table.copy(route)}
        local observer = stub_observer(function() end)
        local handler = function()
            error('Handler is broken')
        end

        pcall(http_middleware.v1(handler, observer), request)
    end)

    t.assert(cg.server:grep_log('Handler is broken'))
end
