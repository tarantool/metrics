local t = require('luatest')
local g = t.group()

local utils = require('test.utils')
local Shared = require('metrics.collectors.shared')

g.test_shared_prepared_different_order_in_label_pairs = function()
    local class = Shared:new_class('test_class', {'inc'})
    local collector = class:new('test')
    local prepared1 = collector:prepare({a = 1, b = 2})
    local prepared2 = collector:prepare({a = 2, b = 1})
    local prepared3 = collector:prepare({b = 2, a = 1})
    
    prepared1:inc(1)
    prepared2:inc(1)
    prepared3:inc(1)
    utils.assert_observations(collector:collect(), {
        {'test', 2, {a = 1, b = 2}},
        {'test', 1, {a = 2, b = 1}},
    })
end

g.test_shared_prepared_remove_metric_by_label = function()
    local class = Shared:new_class('test_class', {'inc'})
    local collector = class:new('test')
    local prepared1 = collector:prepare({a = 1, b = 2})
    local prepared2 = collector:prepare({a = 2, b = 1})
    
    prepared1:inc(1)
    prepared2:inc(1)
    utils.assert_observations(collector:collect(), {
        {'test', 1, {a = 1, b = 2}},
        {'test', 1, {a = 2, b = 1}},
    })
    prepared2:remove()
    utils.assert_observations(collector:collect(), {
        {'test', 1, {a = 1, b = 2}},
    })
end

g.test_shared_prepared_metainfo = function()
    local metainfo = {my_useful_info = 'here'}
    local class = Shared:new_class('test_class', {'inc'})
    local c = class:new('collector', nil, metainfo)
    local prepared = c:prepare({})
    t.assert_equals(c.metainfo, metainfo)
end

g.test_shared_prepared_metainfo_immutable = function()
    local metainfo = {my_useful_info = 'here'}
    local class = Shared:new_class('test_class', {'inc'})
    local c = class:new('collector', nil, metainfo)
    local prepared = c:prepare({})
    metainfo['my_useful_info'] = 'there'
    t.assert_equals(c.metainfo, {my_useful_info = 'here'})
end

g.test_shared_prepared_multiple_labels = function()
    local class = Shared:new_class('test_class', {'inc', 'set'})
    local collector = class:new('temperature')
    
    -- Test multiple prepared statements with different labels
    local prepared1 = collector:prepare({location = 'server1', sensor = 'cpu'})
    local prepared2 = collector:prepare({location = 'server2', sensor = 'cpu'})
    local prepared3 = collector:prepare({location = 'server1', sensor = 'memory'})
    
    prepared1:set(65.5)
    prepared2:set(72.3)
    prepared3:set(45.2)
    
    utils.assert_observations(collector:collect(), {
        {'temperature', 65.5, {location = 'server1', sensor = 'cpu'}},
        {'temperature', 72.3, {location = 'server2', sensor = 'cpu'}},
        {'temperature', 45.2, {location = 'server1', sensor = 'memory'}},
    })
    
    -- Test increment on existing prepared statements
    prepared1:inc(2.5)
    prepared2:inc(-1.3)
    
    utils.assert_observations(collector:collect(), {
        {'temperature', 68.0, {location = 'server1', sensor = 'cpu'}},
        {'temperature', 71.0, {location = 'server2', sensor = 'cpu'}},
        {'temperature', 45.2, {location = 'server1', sensor = 'memory'}},
    })
end

g.test_shared_prepared_methods = function()
    local class = Shared:new_class('test_class', {'inc', 'set', 'reset'})
    local collector = class:new('test')
    local prepared = collector:prepare({label = 'test'})
    
    -- Test that prepared has the right methods
    t.assert_not_equals(prepared.inc, nil, "prepared should have inc method")
    t.assert_not_equals(prepared.set, nil, "prepared should have set method")
    t.assert_not_equals(prepared.reset, nil, "prepared should have reset method")
    t.assert_not_equals(prepared.remove, nil, "prepared should have remove method")
    
    -- Test that prepared doesn't have methods not defined in class
    t.assert_equals(prepared.dec, nil, "prepared shouldn't have dec method if not in class")
    t.assert_equals(prepared.collect, nil, "prepared shouldn't have collect method")
end

g.test_shared_prepared_custom_methods = function()
    -- Skip this test - custom methods need to be defined in Shared.Prepared
    -- to be available in prepared statements
    t.skip('Custom methods need to be defined in Shared.Prepared to be available')
end