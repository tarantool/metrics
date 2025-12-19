local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local Histogram = require('metrics.collectors.histogram')
local utils = require('test.utils')

g.before_all(utils.create_server)
g.after_all(utils.drop_server)

g.before_each(metrics.clear)

g.test_histogram_prepared_unsorted_buckets_error = function()
    t.assert_error_msg_contains('Invalid value for buckets', metrics.histogram, 'latency', nil, {0.9, 0.5})
end

g.test_histogram_prepared_remove_metric_by_label = function()
    local h = Histogram:new('hist', 'some histogram', {2, 4})

    local prepared1 = h:prepare({label = 1})
    local prepared2 = h:prepare({label = 2})

    prepared1:observe(3)
    prepared2:observe(5)

    utils.assert_observations(h:collect(),
        {
            {'hist_count', 1, {label = 1}},
            {'hist_count', 1, {label = 2}},
            {'hist_sum', 3, {label = 1}},
            {'hist_sum', 5, {label = 2}},
            {'hist_bucket', 0, {label = 1, le = 2}},
            {'hist_bucket', 1, {label = 1, le = math.huge}},
            {'hist_bucket', 1, {label = 1, le = 4}},
            {'hist_bucket', 0, {label = 2, le = 4}},
            {'hist_bucket', 1, {label = 2, le = math.huge}},
            {'hist_bucket', 0, {label = 2, le = 2}},
        }
    )

    prepared1:remove()
    utils.assert_observations(h:collect(),
        {
            {'hist_count', 1, {label = 2}},
            {'hist_sum', 5, {label = 2}},
            {'hist_bucket', 0, {label = 2, le = 4}},
            {'hist_bucket', 1, {label = 2, le = math.huge}},
            {'hist_bucket', 0, {label = 2, le = 2}},
        }
    )
end

g.test_histogram_prepared = function()
    local h = metrics.histogram('hist', 'some histogram', {2, 4})
    local prepared = h:prepare({})

    prepared:observe(3)
    prepared:observe(5)

    local collectors = metrics.collectors()
    t.assert_equals(utils.len(collectors), 1, 'histogram seen as only 1 collector')
    local observations = metrics.collect()
    local obs_sum = utils.find_obs('hist_sum', {}, observations)
    local obs_count = utils.find_obs('hist_count', {}, observations)
    local obs_bucket_2 = utils.find_obs('hist_bucket', { le = 2 }, observations)
    local obs_bucket_4 = utils.find_obs('hist_bucket', { le = 4 }, observations)
    local obs_bucket_inf = utils.find_obs('hist_bucket', { le = metrics.INF }, observations)
    t.assert_equals(#observations, 5, '<name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    t.assert_equals(obs_sum.value, 8, '3 + 5 = 8')
    t.assert_equals(obs_count.value, 2, '2 observed values')
    t.assert_equals(obs_bucket_2.value, 0, 'bucket 2 has no values')
    t.assert_equals(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    t.assert_equals(obs_bucket_inf.value, 2, 'bucket +inf has 2 values: 3, 5')

    local prepared_with_labels = h:prepare({ foo = 'bar' })
    prepared_with_labels:observe(3)

    collectors = metrics.collectors()
    t.assert_equals(utils.len(collectors), 1, 'still histogram seen as only 1 collector')
    observations = metrics.collect()
    obs_sum = utils.find_obs('hist_sum', { foo = 'bar' }, observations)
    obs_count = utils.find_obs('hist_count', { foo = 'bar' }, observations)
    obs_bucket_2 = utils.find_obs('hist_bucket', { le = 2, foo = 'bar' }, observations)
    obs_bucket_4 = utils.find_obs('hist_bucket', { le = 4, foo = 'bar' }, observations)
    obs_bucket_inf = utils.find_obs('hist_bucket', { le = metrics.INF, foo = 'bar' }, observations)

    t.assert_equals(#observations, 10, '+ <name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    t.assert_equals(obs_sum.value, 3, '3 = 3')
    t.assert_equals(obs_count.value, 1, '1 observed values')
    t.assert_equals(obs_bucket_2.value, 0, 'bucket 2 has no values')
    t.assert_equals(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    t.assert_equals(obs_bucket_inf.value, 1, 'bucket +inf has 1 value: 3')
end

g.test_histogram_prepared_insert_non_number = function()
    local h = metrics.histogram('hist', 'some histogram', {2, 4})
    local prepared = h:prepare({})

    t.assert_error_msg_contains('Histogram observation should be a number', prepared.observe, prepared, true)
end

g.test_histogram_prepared_insert_cdata = function(cg)
    cg.server:exec(function()
        local h = require('metrics').histogram('hist', 'some histogram', {2, 4})
        local prepared = h:prepare({})
        t.assert_not(prepared:observe(0ULL))
    end)

    local warn = "Using cdata as observation in historgam " ..
        "can lead to unexpected results. " ..
        "That log message will be an error in the future."
    t.assert_not_equals(cg.server:grep_log(warn), nil)
end

g.test_histogram_prepared_with_fixed_labels = function()
    local fixed_labels = {'label1', 'label2'}
    local histogram = metrics.histogram('histogram_with_labels', nil, {2, 4}, {}, fixed_labels)

    local prepared1 = histogram:prepare({label1 = 1, label2 = 'text'})
    prepared1:observe(3)
    utils.assert_observations(histogram:collect(),
        {
            {'histogram_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_sum', 3, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_bucket', 0, {label1 = 1, label2 = 'text', le = 2}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = 4}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = metrics.INF}},
        }
    )

    local prepared2 = histogram:prepare({label2 = 'text', label1 = 2})
    prepared2:observe(5)
    utils.assert_observations(histogram:collect(),
        {
            {'histogram_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_sum', 3, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_bucket', 0, {label1 = 1, label2 = 'text', le = 2}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = 4}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = metrics.INF}},
            {'histogram_with_labels_count', 1, {label1 = 2, label2 = 'text'}},
            {'histogram_with_labels_sum', 5, {label1 = 2, label2 = 'text'}},
            {'histogram_with_labels_bucket', 0, {label1 = 2, label2 = 'text', le = 2}},
            {'histogram_with_labels_bucket', 0, {label1 = 2, label2 = 'text', le = 4}},
            {'histogram_with_labels_bucket', 1, {label1 = 2, label2 = 'text', le = metrics.INF}},
        }
    )

    prepared2:remove()
    utils.assert_observations(histogram:collect(),
        {
            {'histogram_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_sum', 3, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_bucket', 0, {label1 = 1, label2 = 'text', le = 2}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = 4}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = metrics.INF}},
        }
    )
end

g.test_histogram_prepared_missing_label = function()
    local fixed_labels = {'label1', 'label2'}
    local histogram = metrics.histogram('histogram_with_labels', nil, {2, 4}, {}, fixed_labels)

    -- Test that prepare validates labels
    t.assert_error_msg_contains(
        "should match the number of label pairs",
        histogram.prepare, histogram, {label1 = 1, label2 = 'text', label3 = 42})

    local function assert_missing_label_error(fun, ...)
        t.assert_error_msg_contains(
            "is missing",
            fun, histogram, ...)
    end

    assert_missing_label_error(histogram.prepare, {label1 = 1, label3 = 'a'})
end

g.test_histogram_prepared_multiple_labels = function()
    local h = metrics.histogram('http_request_duration_seconds', nil, {0.1, 0.5, 1.0})

    -- Test multiple prepared statements with different labels
    local prepared1 = h:prepare({method = 'GET', endpoint = '/api/users', status = '200'})
    local prepared2 = h:prepare({method = 'POST', endpoint = '/api/users', status = '201'})
    local prepared3 = h:prepare({method = 'GET', endpoint = '/api/products', status = '404'})

    prepared1:observe(0.15)
    prepared2:observe(0.35)
    prepared3:observe(1.2)

    utils.assert_observations(h:collect(),
        {
            {'http_request_duration_seconds_count', 1, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds_sum', 0.15, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/users', status = '200', le = 0.1}},
            {'http_request_duration_seconds_bucket', 1, {method = 'GET', endpoint = '/api/users', status = '200', le = 0.5}},
            {'http_request_duration_seconds_bucket', 1, {method = 'GET', endpoint = '/api/users', status = '200', le = 1.0}},
            {'http_request_duration_seconds_bucket', 1, {method = 'GET', endpoint = '/api/users', status = '200', le = metrics.INF}},
            {'http_request_duration_seconds_count', 1, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds_sum', 0.35, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds_bucket', 0, {method = 'POST', endpoint = '/api/users', status = '201', le = 0.1}},
            {'http_request_duration_seconds_bucket', 1, {method = 'POST', endpoint = '/api/users', status = '201', le = 0.5}},
            {'http_request_duration_seconds_bucket', 1, {method = 'POST', endpoint = '/api/users', status = '201', le = 1.0}},
            {'http_request_duration_seconds_bucket', 1, {method = 'POST', endpoint = '/api/users', status = '201', le = metrics.INF}},
            {'http_request_duration_seconds_count', 1, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds_sum', 1.2, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/products', status = '404', le = 0.1}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/products', status = '404', le = 0.5}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/products', status = '404', le = 1.0}},
            {'http_request_duration_seconds_bucket', 1, {method = 'GET', endpoint = '/api/products', status = '404', le = metrics.INF}},
        }
    )

    -- Test observe on existing prepared statement
    prepared1:observe(0.25)
    utils.assert_observations(h:collect(),
        {
            {'http_request_duration_seconds_count', 2, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds_sum', 0.4, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/users', status = '200', le = 0.1}},
            {'http_request_duration_seconds_bucket', 2, {method = 'GET', endpoint = '/api/users', status = '200', le = 0.5}},
            {'http_request_duration_seconds_bucket', 2, {method = 'GET', endpoint = '/api/users', status = '200', le = 1.0}},
            {'http_request_duration_seconds_bucket', 2, {method = 'GET', endpoint = '/api/users', status = '200', le = metrics.INF}},
            {'http_request_duration_seconds_count', 1, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds_sum', 0.35, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds_bucket', 0, {method = 'POST', endpoint = '/api/users', status = '201', le = 0.1}},
            {'http_request_duration_seconds_bucket', 1, {method = 'POST', endpoint = '/api/users', status = '201', le = 0.5}},
            {'http_request_duration_seconds_bucket', 1, {method = 'POST', endpoint = '/api/users', status = '201', le = 1.0}},
            {'http_request_duration_seconds_bucket', 1, {method = 'POST', endpoint = '/api/users', status = '201', le = metrics.INF}},
            {'http_request_duration_seconds_count', 1, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds_sum', 1.2, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/products', status = '404', le = 0.1}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/products', status = '404', le = 0.5}},
            {'http_request_duration_seconds_bucket', 0, {method = 'GET', endpoint = '/api/products', status = '404', le = 1.0}},
            {'http_request_duration_seconds_bucket', 1, {method = 'GET', endpoint = '/api/products', status = '404', le = metrics.INF}},
        }
    )
end

g.test_histogram_prepared_methods = function()
    local h = metrics.histogram('hist')
    local prepared = h:prepare({label = 'test'})

    -- Test that prepared has the right methods
    t.assert_not_equals(prepared.observe, nil, "prepared should have observe method")
    t.assert_not_equals(prepared.remove, nil, "prepared should have remove method")

    -- Test that prepared doesn't have gauge/counter methods
    t.assert_equals(prepared.inc, nil, "prepared shouldn't have inc method")
    t.assert_equals(prepared.dec, nil, "prepared shouldn't have dec method")
    t.assert_equals(prepared.set, nil, "prepared shouldn't have set method")
    t.assert_equals(prepared.reset, nil, "prepared shouldn't have reset method")
    t.assert_equals(prepared.collect, nil, "prepared shouldn't have collect method")
end
