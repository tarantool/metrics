local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

local Summary = require('metrics.collectors.summary')
local Quantile = require('metrics.quantile')
local metrics = require('metrics')

g.before_each(metrics.clear)

g.test_summary_prepared_collect = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local prepared1 = instance:prepare({})
    local prepared2 = instance:prepare({tag = 'a'})
    local prepared3 = instance:prepare({tag = 'b'})

    prepared1:observe(1)
    prepared1:observe(2)
    prepared1:observe(3)
    prepared2:observe(3)
    prepared2:observe(4)
    prepared2:observe(5)
    prepared2:observe(6)
    prepared3:observe(6)

    utils.assert_observations(instance:collect(), {
        {'latency_count', 3, {}},
        {'latency_sum', 6, {}},
        {'latency', 2, {quantile = 0.5}},
        {'latency', 3, {quantile = 0.9}},
        {'latency', 3, {quantile = 0.99}},
        {'latency_count', 4, {tag = 'a'}},
        {'latency_sum', 18, {tag = 'a'}},
        {'latency', 5, {quantile = 0.5, tag = 'a'}},
        {'latency', 6, {quantile = 0.9, tag = 'a'}},
        {'latency', 6, {quantile = 0.99, tag = 'a'}},
        {'latency_count', 1, {tag = 'b'}},
        {'latency_sum', 6, {tag = 'b'}},
        {'latency', 6, {quantile = 0.5, tag = 'b'}},
        {'latency', 6, {quantile = 0.9, tag = 'b'}},
        {'latency', 6, {quantile = 0.99, tag = 'b'}},
    })
end

local test_data_collect = {
    ['100_values'] = {num_observations = 100, input = {{[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}}},
    ['10k'] = {num_observations = 10^4, input = {{[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}}},
    ['10k_4_age_buckets'] = {num_observations = 10^4, input = {{[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 1, age_buckets_count = 4}}},
}

for test_case, test_data in pairs(test_data_collect) do
    g['test_summary_prepared_collect_' .. test_case] = function()
        local instance = Summary:new('latency', nil, unpack(test_data.input))
        local prepared = instance:prepare({})
        local sum = 0
        for i = 1, test_data.num_observations do
            prepared:observe(i)
            sum = sum + i
        end
        local res = utils.observations_without_timestamps(instance:collect())
        t.assert_items_equals(res[1], {
            label_pairs = {},
            metric_name = "latency_count",
            value = test_data.num_observations,
        })
        t.assert_items_equals(res[2], {
            label_pairs = {},
            metric_name = "latency_sum",
            value = sum,
        })
    end
end

g.test_summary_prepared_4_age_buckets_value_in_each_bucket = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 10, age_buckets_count = 4})
    local prepared = instance:prepare({})
    for i = 1, 10^3 do
        prepared:observe(i)
    end

    local observations = instance:get_observations()
    t.assert_equals(#observations.buckets, 4)

    local q = Quantile.Query(observations.buckets[1], 0.5)
    for _, v in ipairs(observations.buckets) do
        t.assert_equals(q, Quantile.Query(v, 0.5))
    end
end

g.test_summary_prepared_4_age_buckets_rotates = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})
    local prepared = instance:prepare({})

    prepared:observe(2) -- 0.5-quantile now is 2
    prepared:observe(1)
    -- summary rotates at this moment
    -- now head index is 2 and previous head bucket resets
    -- head bucket has 0.5-quantile = 2
    -- previous head was reset and now has 0.5-quantile = 2

    local observations = instance:get_observations().buckets
    local head_quantile = Quantile.Query(observations[2], 0.5)
    local previous_quantile = Quantile.Query(observations[1], 0.5)
    local head_bucket_len = observations[2].b_len + observations[2].stream.n
    local previous_bucket_len = observations[1].b_len + observations[1].stream.n

    t.assert_not_equals(head_bucket_len, previous_bucket_len)
    t.assert_not_equals(head_quantile, previous_quantile)
end

g.test_summary_prepared_full_circle_rotates = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})
    local prepared = instance:prepare({})

    for i = 1, 5 do
        prepared:observe(i)
    end

    local observations = instance:get_observations().buckets
    local head_quantile = Quantile.Query(observations[2], 0.5)
    local previous_quantile = Quantile.Query(observations[1], 0.5)
    local head_bucket_len = observations[2].b_len + observations[2].stream.n
    local previous_bucket_len = observations[1].b_len + observations[1].stream.n

    t.assert_not_equals(head_bucket_len, previous_bucket_len)
    t.assert_not_equals(head_quantile, previous_quantile)
end

g.test_summary_prepared_counter_values_equals = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local prepared = instance:prepare({})
    for i = 1, 10^3 do
        prepared:observe(i)
    end

    local observations = instance:get_observations()
    local count = observations.b_len + observations.stream.n

    t.assert_equals(instance.count_collector.observations[''], count)
end

g.test_summary_prepared_with_age_buckets_refresh_values = function()
    local s1 = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local s2 = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})

    local prepared1 = s1:prepare({})
    local prepared2 = s2:prepare({})

    for i = 1, 10 do
        prepared1:observe(i)
        prepared2:observe(i)
    end
    for i = 0.1, 1, 0.1 do
        prepared1:observe(i)
        prepared2:observe(i)
    end

    t.assert_equals(s1:collect()[5].value, 10)
    t.assert_not_equals(s1:collect()[5].value, s2:collect()[5].value)
end

g.test_summary_prepared_wrong_label = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})

    t.assert_error_msg_contains('Label "quantile" are not allowed in summary',
        instance.prepare, instance, {quantile = 0.5})
end

g.test_summary_prepared_create_summary_without_observations = function()
    local ok, summary = pcall(metrics.summary, 'plain_summary')
    t.assert(ok, summary)
    local prepared = summary:prepare({})
    prepared:observe(0)

    local summary_metrics = utils.find_metric('plain_summary_count', metrics.collect())
    t.assert_equals(#summary_metrics, 1)

    summary_metrics = utils.find_metric('plain_summary_sum', metrics.collect())
    t.assert_equals(#summary_metrics, 1)

    summary_metrics = utils.find_metric('plain_summary', metrics.collect())
    t.assert_not(summary_metrics)
end

g.test_summary_prepared_remove_metric_by_label = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local prepared1 = instance:prepare({tag = 'a'})
    local prepared2 = instance:prepare({tag = 'b'})

    prepared1:observe(3)
    prepared2:observe(6)

    utils.assert_observations(instance:collect(), {
        {'latency_count', 1, {tag = 'a'}},
        {'latency_count', 1, {tag = 'b'}},
        {'latency_sum', 3, {tag = 'a'}},
        {'latency_sum', 6, {tag = 'b'}},
        {'latency', 3, {quantile = 0.5, tag = 'a'}},
        {'latency', 3, {quantile = 0.9, tag = 'a'}},
        {'latency', 3, {quantile = 0.99, tag = 'a'}},
        {'latency', 6, {quantile = 0.5, tag = 'b'}},
        {'latency', 6, {quantile = 0.9, tag = 'b'}},
        {'latency', 6, {quantile = 0.99, tag = 'b'}},
    })

    prepared2:remove()
    utils.assert_observations(instance:collect(), {
        {'latency_count', 1, {tag = 'a'}},
        {'latency_sum', 3, {tag = 'a'}},
        {'latency', 3, {quantile = 0.5, tag = 'a'}},
        {'latency', 3, {quantile = 0.9, tag = 'a'}},
        {'latency', 3, {quantile = 0.99, tag = 'a'}},
    })
end

g.test_summary_prepared_insert_non_number = function()
    local s = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local prepared = s:prepare({})

    t.assert_error_msg_contains('Summary observation should be a number', prepared.observe, prepared, true)
end

g.test_summary_prepared_with_fixed_labels = function()
    local fixed_labels = {'label1', 'label2'}
    local summary = metrics.summary('summary_with_labels', nil, {[0.5]=0.01, [0.9]=0.01}, {}, {}, fixed_labels)

    local prepared1 = summary:prepare({label1 = 1, label2 = 'text'})
    prepared1:observe(42)
    utils.assert_observations(summary:collect(),
        {
            {'summary_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'summary_with_labels_sum', 42, {label1 = 1, label2 = 'text'}},
            {'summary_with_labels', 42, {label1 = 1, label2 = 'text', quantile = 0.5}},
            {'summary_with_labels', 42, {label1 = 1, label2 = 'text', quantile = 0.9}},
        }
    )

    local prepared2 = summary:prepare({label1 = 2, label2 = 'text'})
    prepared2:observe(1)
    utils.assert_observations(summary:collect(),
        {
            {'summary_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'summary_with_labels_sum', 42, {label1 = 1, label2 = 'text'}},
            {'summary_with_labels', 42, {label1 = 1, label2 = 'text', quantile = 0.5}},
            {'summary_with_labels', 42, {label1 = 1, label2 = 'text', quantile = 0.9}},
            {'summary_with_labels_count', 1, {label1 = 2, label2 = 'text'}},
            {'summary_with_labels_sum', 1, {label1 = 2, label2 = 'text'}},
            {'summary_with_labels', 1, {label1 = 2, label2 = 'text', quantile = 0.5}},
            {'summary_with_labels', 1, {label1 = 2, label2 = 'text', quantile = 0.9}},
        }
    )

    prepared2:remove()
    utils.assert_observations(summary:collect(),
        {
            {'summary_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'summary_with_labels_sum', 42, {label1 = 1, label2 = 'text'}},
            {'summary_with_labels', 42, {label1 = 1, label2 = 'text', quantile = 0.5}},
            {'summary_with_labels', 42, {label1 = 1, label2 = 'text', quantile = 0.9}},
        }
    )
end

g.test_summary_prepared_missing_label = function()
    local fixed_labels = {'label1', 'label2'}
    local summary = metrics.summary('summary_with_labels', nil, {[0.5]=0.01}, {}, {}, fixed_labels)

    -- Test that prepare validates labels
    t.assert_error_msg_contains(
        "should match the number of label pairs",
        summary.prepare, summary, {label1 = 1, label2 = 'text', label3 = 42})

    local function assert_missing_label_error(fun, ...)
        t.assert_error_msg_contains(
            "is missing",
            fun, summary, ...)
    end

    assert_missing_label_error(summary.prepare, {label1 = 1, label3 = 'a'})
end

g.test_summary_prepared_multiple_labels = function()
    local s = metrics.summary('http_request_duration_seconds', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})

    -- Test multiple prepared statements with different labels
    local prepared1 = s:prepare({method = 'GET', endpoint = '/api/users', status = '200'})
    local prepared2 = s:prepare({method = 'POST', endpoint = '/api/users', status = '201'})
    local prepared3 = s:prepare({method = 'GET', endpoint = '/api/products', status = '404'})

    prepared1:observe(0.15)
    prepared2:observe(0.35)
    prepared3:observe(1.2)

    utils.assert_observations(s:collect(),
        {
            {'http_request_duration_seconds_count', 1, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds_sum', 0.15, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds', 0.15, {method = 'GET', endpoint = '/api/users', status = '200', quantile = 0.5}},
            {'http_request_duration_seconds', 0.15, {method = 'GET', endpoint = '/api/users', status = '200', quantile = 0.9}},
            {'http_request_duration_seconds', 0.15, {method = 'GET', endpoint = '/api/users', status = '200', quantile = 0.99}},
            {'http_request_duration_seconds_count', 1, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds_sum', 0.35, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds', 0.35, {method = 'POST', endpoint = '/api/users', status = '201', quantile = 0.5}},
            {'http_request_duration_seconds', 0.35, {method = 'POST', endpoint = '/api/users', status = '201', quantile = 0.9}},
            {'http_request_duration_seconds', 0.35, {method = 'POST', endpoint = '/api/users', status = '201', quantile = 0.99}},
            {'http_request_duration_seconds_count', 1, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds_sum', 1.2, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds', 1.2, {method = 'GET', endpoint = '/api/products', status = '404', quantile = 0.5}},
            {'http_request_duration_seconds', 1.2, {method = 'GET', endpoint = '/api/products', status = '404', quantile = 0.9}},
            {'http_request_duration_seconds', 1.2, {method = 'GET', endpoint = '/api/products', status = '404', quantile = 0.99}},
        }
    )

    -- Test observe on existing prepared statement
    prepared1:observe(0.25)
    utils.assert_observations(s:collect(),
        {
            {'http_request_duration_seconds_count', 2, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds_sum', 0.4, {method = 'GET', endpoint = '/api/users', status = '200'}},
            {'http_request_duration_seconds', 0.25, {method = 'GET', endpoint = '/api/users', status = '200', quantile = 0.5}},
            {'http_request_duration_seconds', 0.25, {method = 'GET', endpoint = '/api/users', status = '200', quantile = 0.9}},
            {'http_request_duration_seconds', 0.25, {method = 'GET', endpoint = '/api/users', status = '200', quantile = 0.99}},
            {'http_request_duration_seconds_count', 1, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds_sum', 0.35, {method = 'POST', endpoint = '/api/users', status = '201'}},
            {'http_request_duration_seconds', 0.35, {method = 'POST', endpoint = '/api/users', status = '201', quantile = 0.5}},
            {'http_request_duration_seconds', 0.35, {method = 'POST', endpoint = '/api/users', status = '201', quantile = 0.9}},
            {'http_request_duration_seconds', 0.35, {method = 'POST', endpoint = '/api/users', status = '201', quantile = 0.99}},
            {'http_request_duration_seconds_count', 1, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds_sum', 1.2, {method = 'GET', endpoint = '/api/products', status = '404'}},
            {'http_request_duration_seconds', 1.2, {method = 'GET', endpoint = '/api/products', status = '404', quantile = 0.5}},
            {'http_request_duration_seconds', 1.2, {method = 'GET', endpoint = '/api/products', status = '404', quantile = 0.9}},
            {'http_request_duration_seconds', 1.2, {method = 'GET', endpoint = '/api/products', status = '404', quantile = 0.99}},
        }
    )
end

g.test_summary_prepared_methods = function()
    local s = metrics.summary('summary')
    local prepared = s:prepare({label = 'test'})

    -- Test that prepared has the right methods
    t.assert_not_equals(prepared.observe, nil, "prepared should have observe method")
    t.assert_not_equals(prepared.remove, nil, "prepared should have remove method")
    -- prepared statements don't have collect method (collect is on the collector)

    -- Test that prepared doesn't have gauge/counter methods
    t.assert_equals(prepared.inc, nil, "prepared shouldn't have inc method")
    t.assert_equals(prepared.dec, nil, "prepared shouldn't have dec method")
    t.assert_equals(prepared.set, nil, "prepared shouldn't have set method")
    t.assert_equals(prepared.reset, nil, "prepared shouldn't have reset method")
end
