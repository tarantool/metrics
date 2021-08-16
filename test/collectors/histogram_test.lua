local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local Histogram = require('metrics.collectors.histogram')
local utils = require('test.utils')

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
