local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

local Summary = require('metrics.collectors.summary')
local Quantile = require('metrics.quantile')
local metrics = require('metrics')

g.before_each = function()
    metrics.clear()
end

g.test_collect = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    instance:observe(1)
    instance:observe(2)
    instance:observe(3)
    instance:observe(3, {tag = 'a'})
    instance:observe(4, {tag = 'a'})
    instance:observe(5, {tag = 'a'})
    instance:observe(6, {tag = 'a'})
    instance:observe(6, {tag = 'b'})

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
    g['test_collect_' .. test_case] = function()
        local instance = Summary:new('latency', nil, unpack(test_data.input))
        local sum = 0
        for i = 1, test_data.num_observations do
            instance:observe(i)
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

g.test_summary_4_age_buckets_value_in_each_bucket = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 10, age_buckets_count = 4})
    for i = 1, 10^3 do
        instance:observe(i)
    end

    local observations = instance:get_observations()
    t.assert_equals(#observations.buckets, 4)

    local q = Quantile.Query(observations.buckets[1], 0.5)
    for _, v in ipairs(observations.buckets) do
        t.assert_equals(q, Quantile.Query(v, 0.5))
    end
end

g.test_summary_4_age_buckets_rotates = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})

    instance:observe(2) -- 0.5-quantile now is 2
    instance:observe(1)
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

g.test_summary_full_circle_rotates = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})

    for i = 1, 5 do
        instance:observe(i)
    end

    local observations = instance:get_observations().buckets
    local head_quantile = Quantile.Query(observations[2], 0.5)
    local previous_quantile = Quantile.Query(observations[1], 0.5)
    local head_bucket_len = observations[2].b_len + observations[2].stream.n
    local previous_bucket_len = observations[1].b_len + observations[1].stream.n

    t.assert_not_equals(head_bucket_len, previous_bucket_len)
    t.assert_not_equals(head_quantile, previous_quantile)
end

g.test_summary_counter_values_equals = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    for i = 1, 10^3 do
        instance:observe(i)
    end

    local observations = instance:get_observations()
    local count = observations.b_len + observations.stream.n

    t.assert_equals(instance.count_collector.observations[''], count)
end

g.test_summary_with_age_buckets_refresh_values = function()
    local s1 = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local s2 = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})

    for i = 1, 10 do
        s1:observe(i)
        s2:observe(i)
    end
    for i = 0.1, 1, 0.1 do
        s1:observe(i)
        s2:observe(i)
    end

    t.assert_equals(s1:collect()[5].value, 10)
    t.assert_not_equals(s1:collect()[5].value, s2:collect()[5].value)
end

g.test_summary_wrong_label = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        {max_age_time = 0, age_buckets_count = 4})

    t.assert_error_msg_contains('Label "quantile" are not allowed in summary',
        instance.observe, instance, 1, {quantile = 0.5})
end

g.test_create_summary_without_observations = function()
    local ok, summary = pcall(metrics.summary, 'plain_summary')
    t.assert(ok, summary)
    summary:observe(0)

    local summary_metrics = utils.find_metric('plain_summary_count', metrics.collect())
    t.assert_equals(#summary_metrics, 1)

    summary_metrics = utils.find_metric('plain_summary_sum', metrics.collect())
    t.assert_equals(#summary_metrics, 1)

    summary_metrics = utils.find_metric('plain_summary', metrics.collect())
    t.assert_not(summary_metrics)

end

local test_data_wrong_input = {
    objectives = {error = 'Invalid value for objectives', input = {'summary', nil, {0.5, 0.9, 0.99}}},
    max_age = {error = 'Max age must be positive', input = {'summary', nil, {[0.5]=0.01}, {max_age_time = -1}}},
    age_buckets = {error = 'Age buckets count must be greater or equal than one',
        input = {'summary', nil, {[0.5]=0.01}, {max_age_time = 1, age_buckets_count = -1}}},
    age_buckets_without_max_age = {error = 'Age buckets count and max age must be present only together',
        input = {'summary', nil, {[0.5]=0.01}, {age_buckets_count = 1}}},
    max_age_without_age_buckets = {error = 'Age buckets count and max age must be present only together',
        input = {'summary', nil, {[0.5]=0.01}, {max_age_time = 1}}},
    bad_collector_name_type = {error = 'bad argument', input = {nil}},
    bad_help_string_type = {error = 'bad argument', input = {'summary', {}}},
    bad_objectives_type = {error = 'bad argument', input = {'summary', 'help', 'objectives'}},
    bad_max_age_type = {error = 'bad argument', input = {'summary', 'help', {[0.5]=0.01},
        {max_age_time = '1', age_buckets_count = 1}}},
    bad_age_buckets_type = {error = 'bad argument', input = {'summary', 'help', {[0.5]=0.01},
        {max_age_time = 1, age_buckets_count = '1'}}},
}

for case_name, test_data in pairs(test_data_wrong_input) do
    g['test_summary_wrong_input_' .. case_name] = function()
        t.assert_error_msg_contains(test_data.error, metrics.summary, unpack(test_data.input))
    end
end

g.test_remove_metric_by_label = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    instance:observe(3, {tag = 'a'})
    instance:observe(6, {tag = 'b'})

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

    instance:remove({tag = 'b'})

    utils.assert_observations(instance:collect(), {
        {'latency_count', 1, {tag = 'a'}},
        {'latency_sum', 3, {tag = 'a'}},
        {'latency', 3, {quantile = 0.5, tag = 'a'}},
        {'latency', 3, {quantile = 0.9, tag = 'a'}},
        {'latency', 3, {quantile = 0.99, tag = 'a'}},
    })
end
