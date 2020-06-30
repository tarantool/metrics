local t = require('luatest')
local g = t.group('latency_observer')

local shared = require('metrics.collectors.shared')

local fiber = require('fiber')

local function stub_observer(observe)
    return {
        observe = observe or function(...) return ... end,
        observe_latency = shared.observe_latency,
    }
end

g.before_all(function()
    g.observer = stub_observer()
end)

local function work_fn(work_time, ...)
    fiber.sleep(work_time)
    return ...
end

local function work_fn_raise_error(work_time)
    fiber.sleep(work_time)
    error('caused error')
end

g.test_measured_fn_return_result = function()
    local result = {status = 200}
    t.assert_equals(
        g.observer:observe_latency({name = 'echo'}, work_fn, 0.0, result),
        result
    )
end

g.test_measured_fn_raise_error = function()
    t.assert_error_msg_content_equals(
        'caused error',
        function()
            return g.observer:observe_latency({name = 'raise_error'}, work_fn_raise_error, 0.0)
        end
    )
end

g.test_measured_fn_return_error = function()
    local ok, err = g.observer:observe_latency({name = 'return_error'}, work_fn, 0.0, nil, 'returned error')
    t.assert_equals(ok, nil)
    t.assert_equals(err, 'returned error')
end

g.test_dynamic_label_pairs = function()
    local obs = nil
    local observer = stub_observer(function(_, _, label_pairs)
        obs = {label_pairs = label_pairs}
    end)

    local label_pairs_gen_fn = function(ok, _, _) return {status=tostring(ok)} end

    observer:observe_latency(label_pairs_gen_fn, work_fn, 0.0)
    t.assert_equals(obs.label_pairs, {status = 'true'})

    pcall(function() observer:observe_latency(label_pairs_gen_fn, work_fn_raise_error, 0.0) end)
    t.assert_equals(obs.label_pairs, {status = 'false'})
end

g.test_time_measurement = function()
    local obs = nil
    local observer = stub_observer(function(_, value, _) obs = {value = value} end)

    local work_times = {0.07, 0.04, 0.03, 0.01}
    for _, time in ipairs(work_times) do
        observer:observe_latency({}, work_fn, time)
        t.assert_almost_equals(obs.value, time, 0.001)
    end
end

g.test_time_measurement_with_error = function()
    local obs = nil
    local observer = stub_observer(function(_, value, label_pairs)
        obs = {value = value, label_pairs = label_pairs}
    end)

    local work_times = {0.07, 0.04, 0.03, 0.01}
    for _, time in ipairs(work_times) do
        pcall(function() observer:observe_latency(
            function(ok, _, _) return {status = tostring(ok)} end,
            work_fn_raise_error,
            time
        ) end)
        t.assert_equals(obs.label_pairs, {status = 'false'})
        t.assert_almost_equals(obs.value, time, 0.001)
    end
end
