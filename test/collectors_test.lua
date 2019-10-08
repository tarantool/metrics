#!/usr/bin/env tarantool

local t = require('luatest')
local g = t.group('collectors')

local metrics = require('metrics')
local utils = require('test.utils')

g.before_all = function()
    box.cfg{}
    box.schema.user.grant(
        'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
    )
end

local function ensure_throws(desc, fun)
   local ok, _ = pcall(fun)
   t.assertTrue(not ok, desc .. ' throws')
end

g.test_counter = function()
    ensure_throws('metrics.counter() w/o parameters', function()
        metrics.counter()
    end)

    ensure_throws('metrics.counter() w/ name as number', function()
        metrics.counter(2)
    end)

    -- delete all previous collectors
    metrics.clear()

    local c = metrics.counter('cnt', 'some counter')

    c:inc(3)
    c:inc(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('cnt', {}, observations)
    t.assertEquals(#collectors, 1, 'counter seen as only collector')
    t.assertEquals(obs.value, 8, '3 + 5 = 8 (via metrics.collectors())')

    t.assertEquals(c:collect()[1].value, 8, '3 + 5 = 8')

    ensure_throws('counter:inc(<negative value>)', function()
        c:inc(-1)
    end)
    ensure_throws('counter:dec(...)', function()
        c:dec(1)
    end)

    c:inc(0)

    t.assertEquals(c:collect()[1].value, 8, '8 + 0 = 8')
end

g.test_gauge = function()
    ensure_throws('metrics.gauge() w/o parameters', function()
        metrics.gauge()
    end)

    ensure_throws('metrics.gauge() w/ name as number', function()
        metrics.gauge(2)
    end)

    -- delete all previous collectors
    metrics.clear()

    local gauge = metrics.gauge('gauge', 'some gauge')

    gauge:inc(3)
    gauge:dec(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = utils.find_obs('gauge', {}, observations)
    t.assertEquals(#collectors, 1, 'gauge seen as only collector')
    t.assertEquals(obs.value, -2, '3 - 5 = -2 (via metrics.collectors())')

    t.assertEquals(gauge:collect()[1].value, -2, '3 - 5 = -2')

    gauge:set(-8)

    t.assertEquals(gauge:collect()[1].value, -8, 'after set(-8) = -8')

    gauge:inc(-1)
    gauge:dec(-2)

    t.assertEquals(gauge:collect()[1].value, -7, '-8 + (-1) - (-2)')
end

g.test_histogram = function()
    ensure_throws('metrics.histogram() w/o parameters', function()
        metrics.histogram()
    end)

    ensure_throws('metrics.histogram() w/ name as number', function()
        metrics.histogram(2)
    end)

    -- delete all previous collectors
    metrics.clear()

    local h = metrics.histogram('hist', 'some histogram', {2, 4})

    h:observe(3)
    h:observe(5)

    local collectors = metrics.collectors()
    t.assertEquals(#collectors, 1, 'histogram seen as only 1 collector')
    local observations = metrics.collect()
    local obs_sum = utils.find_obs('hist_sum', {}, observations)
    local obs_count = utils.find_obs('hist_count', {}, observations)
    local obs_bucket_2 = utils.find_obs('hist_bucket', {le = 2}, observations)
    local obs_bucket_4 = utils.find_obs('hist_bucket', {le = 4}, observations)
    local obs_bucket_inf = utils.find_obs('hist_bucket', {le = metrics.INF}, observations)
    t.assertEquals(#observations, 5, '<name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    t.assertEquals(obs_sum.value, 8, '3 + 5 = 8')
    t.assertEquals(obs_count.value, 2, '2 observed values')
    t.assertEquals(obs_bucket_2.value, 0, 'bucket 2 has no values')
    t.assertEquals(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    t.assertEquals(obs_bucket_inf.value, 2, 'bucket +inf has 2 values: 3, 5')

    h:observe(3, {foo = 'bar'})

    collectors = metrics.collectors()
    t.assertEquals(#collectors, 1, 'still histogram seen as only 1 collector')
    observations = metrics.collect()
    obs_sum = utils.find_obs('hist_sum', {foo = 'bar'}, observations)
    obs_count = utils.find_obs('hist_count', {foo = 'bar'}, observations)
    obs_bucket_2 = utils.find_obs('hist_bucket', {le = 2, foo = 'bar'}, observations)
    obs_bucket_4 = utils.find_obs('hist_bucket', {le = 4, foo = 'bar'}, observations)
    obs_bucket_inf = utils.find_obs('hist_bucket', {le = metrics.INF, foo = 'bar'}, observations)

    t.assertEquals(#observations, 10, '+ <name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    t.assertEquals(obs_sum.value, 3, '3 = 3')
    t.assertEquals(obs_count.value, 1, '1 observed values')
    t.assertEquals(obs_bucket_2.value, 0, 'bucket 2 has no values')
    t.assertEquals(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    t.assertEquals(obs_bucket_inf.value, 1, 'bucket +inf has 1 value: 3')
end
