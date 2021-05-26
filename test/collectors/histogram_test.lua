local t = require('luatest')
local g = t.group()

local metrics = require('metrics')

g.test_unsorted_buckets_error = function()
    t.assert_error_msg_contains('Invalid value for buckets', metrics.histogram, 'latency', nil, {0.9, 0.5})
end
