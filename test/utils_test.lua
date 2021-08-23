local t = require('luatest')
local g = t.group()

local utils = require('metrics.utils')

g.test_set_gauge = function()
    local gauge = utils.set_gauge('gauge', 'gauge info', 10)

    t.assert_equals(gauge.name, 'tnt_gauge')
    t.assert_equals(gauge.help, 'gauge info')
    t.assert_equals(gauge.observations[''], 10)
end

g.test_set_counter = function()
    local counter = utils.set_counter('counter', 'counter info', 10)

    t.assert_equals(counter.name, 'tnt_counter')
    t.assert_equals(counter.help, 'counter info')
    t.assert_equals(counter.observations[''], 10)

    utils.set_counter('counter', 'counter info', 20)
    t.assert_equals(counter.observations[''], 20)
end

g.test_set_gauge_prefix = function()
    local gauge = utils.set_gauge('gauge', 'gauge info', 10, nil, 'custom_')

    t.assert_equals(gauge.name, 'custom_gauge')
    t.assert_equals(gauge.help, 'gauge info')
    t.assert_equals(gauge.observations[''], 10)
end

g.test_set_counter_prefix = function()
    local counter = utils.set_counter('counter', 'counter info', 10, nil, 'custom_')

    t.assert_equals(counter.name, 'custom_counter')
    t.assert_equals(counter.help, 'counter info')
    t.assert_equals(counter.observations[''], 10)

    utils.set_counter('counter', 'counter info', 20, nil, 'custom_')
    t.assert_equals(counter.observations[''], 20)
end

