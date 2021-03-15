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
    ['10k_4_age_buckets'] = {num_observations = 10^4, input = {{[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 1, 4}},
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
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 10, 4)
    for i = 1, 10^3 do
        instance:observe(i)
    end

    t.assert_equals(#instance.observation_buckets[''], 4)

    local q = Quantile.Query(instance.observations[''], 0.5)
    for _,v in ipairs(instance.observation_buckets['']) do
        t.assert_equals(q, Quantile.Query(v, 0.5))
    end
end

g.test_summary_4_age_buckets_rotates = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 0, 4)

    instance:observe(1)
    instance:observe(1) -- summary rotates at this moment

    local q = Quantile.Query(instance.observations[''], 0.5)
    local q1 = Quantile.Query(instance.observation_buckets[''][4], 0.5)
    local last_bucket_len = instance.observation_buckets[''][4].b_len + instance.observation_buckets[''][4].stream.n
    local first_bucket_len = instance.observations[''].b_len + instance.observations[''].stream.n

    t.assert_not_equals(last_bucket_len, first_bucket_len)
    t.assert_not_equals(q, q1)
end

g.test_summary_counter_values_equals = function()
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    for i = 1, 10^3 do
        instance:observe(i)
    end

    local count = instance.observations[''].b_len + instance.observations[''].stream.n

    t.assert_equals(instance.count_collector.observations[''], count)
end

g.test_summary_with_age_buckets_refresh_values = function()
    local s1 = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})
    local s2 = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 0, 4)

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
    local instance = Summary:new('latency', nil, {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 0, 4)

    t.assert_error_msg_contains('Label "quantile" are not allowed in summary',
        instance.observe, instance, 1, {quantile = 0.5})
end

local test_data_wrong_input = {
    objectives = {error = 'Invalid value for objectives', input = {'summary', nil, {0.5, 0.9, 0.99}}},
    max_age = {error = 'Max age must be positive', input = {'summary', nil, {[0.5]=0.01}, -1}},
    age_buckets = {error = 'Age buckets count must be greater or equal than one',
        input = {'summary', nil, {[0.5]=0.01}, 1, -1}},
    age_buckets_without_max_age = {error = 'Age buckets count and max age must be present only together',
        input = {'summary', nil, {[0.5]=0.01}, nil, 1}},
    max_age_without_age_buckets = {error = 'Age buckets count and max age must be present only together',
        input = {'summary', nil, {[0.5]=0.01}, 1, nil}},
    bad_collector_name_type = {error = 'bad argument', input = {nil}},
    bad_help_string_type = {error = 'bad argument', input = {'summary', {}}},
    bad_objectives_type = {error = 'bad argument', input = {'summary', 'help', 'objectives'}},
    bad_max_age_type = {error = 'bad argument', input = {'summary', 'help', {[0.5]=0.01}, '1', 1}},
    bad_age_buckets_type = {error = 'bad argument', input = {'summary', 'help', {[0.5]=0.01}, 1, '1'}},
}

for case_name, test_data in pairs(test_data_wrong_input) do
    g['test_summary_wrong_input_' .. case_name] = function()
        t.assert_error_msg_contains(test_data.error, metrics.summary, unpack(test_data.input))
    end
end
