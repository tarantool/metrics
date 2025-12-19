local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local Histogram = require('metrics.collectors.histogram')
local utils = require('test.utils')

g.before_all(utils.create_server)
g.after_all(utils.drop_server)

g.before_each(metrics.clear)

g.test_unsorted_buckets_error = function()
    t.assert_error_msg_contains('Invalid value for buckets', metrics.histogram, 'latency', nil, {0.9, 0.5})
end

g.test_remove_metric_by_label = function()
    local h = Histogram:new('hist', 'some histogram', {2, 4})

    h:observe(3, {label = 1})
    h:observe(5, {label = 2})

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

    h:remove({label = 1})
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

g.test_histogram = function()
    t.assert_error_msg_contains("bad argument #1 to histogram (string expected, got nil)", function()
        metrics.histogram()
    end)

    t.assert_error_msg_contains("bad argument #1 to histogram (string expected, got number)", function()
        metrics.histogram(2)
    end)

    local h = metrics.histogram('hist', 'some histogram', {2, 4})

    h:observe(3)
    h:observe(5)

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

    h:observe(3, { foo = 'bar' })

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

g.test_insert_non_number = function()
    local h = metrics.histogram('hist', 'some histogram', {2, 4})

    t.assert_error_msg_contains('Histogram observation should be a number', h.observe, h, true)
end

g.test_insert_cdata = function(cg)
    cg.server:exec(function()
        local h = require('metrics').histogram('hist', 'some histogram', {2, 4})
        t.assert_not(h:observe(0ULL))
    end)

    local warn = "Using cdata as observation in historgam " ..
        "can lead to unexpected results. " ..
        "That log message will be an error in the future."
    t.assert_not_equals(cg.server:grep_log(warn), nil)
end

g.test_metainfo = function()
    local metainfo = {my_useful_info = 'here'}
    local h = metrics.histogram('hist', 'some histogram', {2, 4}, metainfo)
    t.assert_equals(h.metainfo, metainfo)
    t.assert_equals(h.sum_collector.metainfo, metainfo)
    t.assert_equals(h.count_collector.metainfo, metainfo)
    t.assert_equals(h.bucket_collector.metainfo, metainfo)
end

g.test_metainfo_immutable = function()
    local metainfo = {my_useful_info = 'here'}
    local h = metrics.histogram('hist', 'some histogram', {2, 4}, metainfo)
    metainfo['my_useful_info'] = 'there'
    t.assert_equals(h.metainfo, {my_useful_info = 'here'})
    t.assert_equals(h.sum_collector.metainfo, {my_useful_info = 'here'})
    t.assert_equals(h.count_collector.metainfo, {my_useful_info = 'here'})
    t.assert_equals(h.bucket_collector.metainfo, {my_useful_info = 'here'})
end

g.test_histogram_with_fixed_labels = function()
    local fixed_labels = {'label1', 'label2'}
    local histogram = metrics.histogram('histogram_with_labels', nil, {2, 4}, {}, fixed_labels)

    histogram:observe(3, {label1 = 1, label2 = 'text'})
    utils.assert_observations(histogram:collect(),
        {
            {'histogram_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_sum', 3, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_bucket', 0, {label1 = 1, label2 = 'text', le = 2}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = 4}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = metrics.INF}},
        }
    )

    histogram:observe(5, {label2 = 'text', label1 = 2})
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

    histogram:remove({label1 = 2, label2 = 'text'})
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

g.test_histogram_missing_label = function()
    local fixed_labels = {'label1', 'label2'}
    local histogram = metrics.histogram('histogram_with_labels', nil, {2, 4}, {}, fixed_labels)

    histogram:observe(42, {label1 = 1, label2 = 'text'})
    utils.assert_observations(histogram:collect(),
        {
            {'histogram_with_labels_count', 1, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_sum', 42, {label1 = 1, label2 = 'text'}},
            {'histogram_with_labels_bucket', 0, {label1 = 1, label2 = 'text', le = 2}},
            {'histogram_with_labels_bucket', 0, {label1 = 1, label2 = 'text', le = 4}},
            {'histogram_with_labels_bucket', 1, {label1 = 1, label2 = 'text', le = metrics.INF}},
        }
    )

    t.assert_error_msg_contains(
        "Invalid label_pairs: expected a table when label_keys is provided",
        histogram.observe, histogram, 42, 1)

    t.assert_error_msg_contains(
        "should match the number of label pairs",
        histogram.observe, histogram, 42, {label1 = 1, label2 = 'text', label3 = 42})

    local function assert_missing_label_error(fun, ...)
        t.assert_error_msg_contains(
            "is missing",
            fun, histogram, ...)
    end

    assert_missing_label_error(histogram.observe, 1, {label1 = 1, label3 = 'a'})
    assert_missing_label_error(histogram.remove, {label2 = 0, label3 = 'b'})
end
