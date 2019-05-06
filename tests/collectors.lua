#!/usr/bin/env tarantool

local metrics = require('metrics')
local tap = require('tap')

-- initialize tarantool
box.cfg{}                           -- luacheck: ignore
box.schema.user.grant(              -- luacheck: ignore
    'guest', 'read,write,execute', 'universe', nil, {if_not_exists = true}
)

local function ensure_throws(test, desc, f)
    local ok, _ = pcall(f)
    test:ok(not ok, desc .. ' throws')
end

-- a < b
local function subset_of(a, b)
    for name, value in pairs(a) do
        if b[name] ~= value then
            return false
        end
    end
    return true
end

-- a = b
local function equal_sets(a, b)
    return subset_of(a, b) and subset_of(b, a)
end

local function find_obs(metric_name, label_pairs, observations)
    for _, obs in pairs(observations) do
        local same_label_pairs = equal_sets(obs.label_pairs, label_pairs)
        if obs.metric_name == metric_name and same_label_pairs then
            return obs
        end
    end
    assert(false, 'haven\'t found observation')
end

local test = tap.test("http")
test:plan(3)

test:test('counter', function(test)
    test:plan(8)

    ensure_throws(test, 'metrics.counter() w/o parameters', function()
        metrics.counter()
    end)

    ensure_throws(test, 'metrics.counter() w/ name as number', function()
        metrics.counter(2)
    end)

    -- delete all previous collectors
    metrics.clear()

    test:diag("create counter")
    local c = metrics.counter('cnt', 'some counter')

    test:diag("inc(3), inc(5)")
    c:inc(3)
    c:inc(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = find_obs('cnt', {}, observations)
    test:is(#collectors, 1, 'counter seen as only collector')
    test:is(obs.value, 8, '3 + 5 = 8 (via metrics.collectors())')

    test:is(c:collect()[1].value, 8, '3 + 5 = 8')

    ensure_throws(test, 'counter:inc(<negative value>)', function()
        c:inc(-1)
    end)
    ensure_throws(test, 'counter:dec(...)', function()
        c:dec(1)
    end)

    test:diag('inc(0)')
    c:inc(0)

    test:is(c:collect()[1].value, 8, '8 + 0 = 8')
end)

test:test('gauge', function(test)
    test:plan(7)

    ensure_throws(test, 'metrics.gauge() w/o parameters', function()
        metrics.gauge()
    end)

    ensure_throws(test, 'metrics.gauge() w/ name as number', function()
        metrics.gauge(2)
    end)

    -- delete all previous collectors
    metrics.clear()

    test:diag("create gauge")
    local g = metrics.gauge('gauge', 'some gauge')

    test:diag("inc(3), dec(5)")
    g:inc(3)
    g:dec(5)

    local collectors = metrics.collectors()
    local observations = metrics.collect()
    local obs = find_obs('gauge', {}, observations)
    test:is(#collectors, 1, 'gauge seen as only collector')
    test:is(obs.value, -2, '3 - 5 = -2 (via metrics.collectors())')

    test:is(g:collect()[1].value, -2, '3 - 5 = -2')

    test:diag('set(-8)')
    g:set(-8)

    test:is(g:collect()[1].value, -8, 'after set(-8) = -8')

    test:diag('inc(-8) dec(-2)')
    g:inc(-1)
    g:dec(-2)

    test:is(g:collect()[1].value, -7, '-8 + (-1) - (-2)')
end)

test:test('histogram', function(test)
    test:plan(16)

    ensure_throws(test, 'metrics.histogram() w/o parameters', function()
        metrics.histogram()
    end)

    ensure_throws(test, 'metrics.histogram() w/ name as number', function()
        metrics.histogram(2)
    end)

    -- delete all previous collectors
    metrics.clear()

    test:diag("create histogram with {2, 4} buckets")
    local h = metrics.histogram('hist', 'some histogram', {2, 4})

    test:diag("observe(3), observe(5)")
    h:observe(3)
    h:observe(5)

    local collectors = metrics.collectors()
    test:is(#collectors, 1, 'histogram seen as only 1 collector')
    local observations = metrics.collect()
    local obs_sum = find_obs('hist_sum', {}, observations)
    local obs_count = find_obs('hist_count', {}, observations)
    local obs_bucket_2 = find_obs('hist_bucket', {le = 2}, observations)
    local obs_bucket_4 = find_obs('hist_bucket', {le = 4}, observations)
    local obs_bucket_inf = find_obs('hist_bucket', {le = metrics.INF}, observations)
    test:is(#observations, 5, '<name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    test:is(obs_sum.value, 8, '3 + 5 = 8')
    test:is(obs_count.value, 2, '2 observed values')
    test:is(obs_bucket_2.value, 0, 'bucket 2 has no values')
    test:is(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    test:is(obs_bucket_inf.value, 2, 'bucket +inf has 2 values: 3, 5')

    test:diag("observe(3) with {foo=bar} label-pairs")
    h:observe(3, {foo = 'bar'})

    collectors = metrics.collectors()
    test:is(#collectors, 1, 'still histogram seen as only 1 collector')
    observations = metrics.collect()
    obs_sum = find_obs('hist_sum', {foo = 'bar'}, observations)
    obs_count = find_obs('hist_count', {foo = 'bar'}, observations)
    obs_bucket_2 = find_obs('hist_bucket', {le = 2, foo = 'bar'}, observations)
    obs_bucket_4 = find_obs('hist_bucket', {le = 4, foo = 'bar'}, observations)
    obs_bucket_inf = find_obs('hist_bucket', {le = metrics.INF, foo = 'bar'}, observations)

    test:is(#observations, 10, '+ <name>_sum, <name>_count, and <name>_bucket with 3 labelpairs')
    test:is(obs_sum.value, 3, '3 = 3')
    test:is(obs_count.value, 1, '1 observed values')
    test:is(obs_bucket_2.value, 0, 'bucket 2 has no values')
    test:is(obs_bucket_4.value, 1, 'bucket 4 has 1 value: 3')
    test:is(obs_bucket_inf.value, 1, 'bucket +inf has 1 value: 3')
end)

os.exit(test:check() and 0 or 1)
