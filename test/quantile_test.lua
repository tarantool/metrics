local quantile = require('metrics.quantile')
local fiber = require('fiber')
local ffi = require('ffi')
local t = require('luatest')
local g = t.group('quantile')

local q = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})

-- Tests from
-- https://github.com/beorn7/perks/blob/37c8de3658fcb183f997c4e13e8337516ab753e6/quantile/stream_test.go#L98

local function getPerc(x, p, eps)
    local low = math.ceil(#x * (p - eps)) + 1
    if low < 1 then
        low = 1
    end
    local upper = math.ceil(#x * (p + eps)) + 1
    if upper > #x then
        upper = #x
    end

    return x[low], x[upper]
end

local x = {}
math.randomseed(0)
for i = 1, 10^4 + 100 do
    local m = math.random() * 10^6
    -- Add 5% asymmetric outliers.
    if i % 20 == 0 then
        m = m^2 + 1
    end
    table.insert(x, m)
    quantile.Insert(q, m)
end

table.sort(x)

local function assert_quantile(quan)
    local wlow, wupper = getPerc(x, quan, 0.01)
    local d = quantile.Query(q, quan)
    t.assert_le(wlow, d)
    t.assert_le(d, wupper)
end

g.test_query_05 = function()
    assert_quantile(0.5)
end

g.test_query_09 = function()
    assert_quantile(0.9)
end

g.test_query_099 = function()
    assert_quantile(0.99)
end

g.test_wrong_quantiles = function()
    t.assert_error_msg_contains(
        'Quantile must be in [0; 1]',
        quantile.NewTargeted,
        {0.5, 0.9, 0.99}
    )
end

g.test_wrong_max_samples = function()
    t.assert_error_msg_contains(
        'max_samples must be positive',
        quantile.NewTargeted,
        {[0.5]=0.01, [0.9]=0.01, [0.99]=0.01},
        0
    )
end

local ARR_SIZE = 500

local function assert_sorted(arr, low, high)
    for i = low + 1, high do
        t.assert(arr[i] >= arr[i-1])
    end
end

g.test_low_values_sorted = function()
    local lows = ffi.new('double[?]', ARR_SIZE)
    for i = 0, ARR_SIZE - 1 do
        lows[i] = math.random()*10^-6
    end
    quantile.quicksort(lows, 0, ARR_SIZE - 1)
    assert_sorted(lows, 0, ARR_SIZE - 1)
end

g.test_random_values_sorted = function()
    local rands = ffi.new('double[?]', ARR_SIZE)
    for i = 0, ARR_SIZE - 1 do
        rands[i] = math.random()*2*10^3 - 10^3
    end
    quantile.quicksort(rands, 0, ARR_SIZE - 1)
    assert_sorted(rands, 0, ARR_SIZE - 1)
end

g.test_low_bound_negative = function()
    local empty = ffi.new('double[?]', 2)
    t.assert_error_msg_contains(
        'Low bound must be non-negative',
        quantile.quicksort,
        empty,
        -1,
        1
    )
end

g.test_high_bound_higher_array_size = function()
    local empty = ffi.new('double[?]', 2)
    t.assert_error_msg_contains(
        'Upper bound must be lower than array size',
        quantile.quicksort,
        empty,
        1,
        10
    )
end

g.test_not_sorted = function()
    local array = ffi.new('double[?]', 2)
    array[0] = math.huge
    array[1] = -math.huge
    quantile.quicksort(array, 0, 0)
    t.assert_not(array[1] >= array[0])
end

g.test_package_reload = function()
    package.loaded['metrics.quantile'] = nil
    local ok, quantile_package = pcall(require, 'metrics.quantile')
    t.assert(ok, quantile_package)
end

g.test_fiber_yield = function()
    local q1 = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 1000)

    for _=1,10 do
        fiber.create(function()
            for _=1,1e2 do
                t.assert(q1.b_len < q1.__max_samples)
                quantile.Insert(q1, math.random(1000))
            end
        end)
    end

    for _=1,10 do
        t.assert(q1.b_len < q1.__max_samples)
        quantile.Insert(q1, math.random(1))
    end
end

g.test_query_on_empty_quantile = function()
    local emptyQuantile = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})

    local res = quantile.Query(emptyQuantile, 0.99)

    t.assert_nan(res)
end

g.test_reset = function()
    local Quantile = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 10)
    for _ = 1,20 do
        quantile.Insert(Quantile, math.random())
    end

    local res = quantile.Query(Quantile, 0.99)
    t.assert_not_nan(res)

    quantile.Reset(Quantile)

    res = quantile.Query(Quantile, 0.99)
    t.assert_nan(res)
end

g.test_quantile_insert_works_after_reset = function()
    local Quantile = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 10)

    quantile.Insert(Quantile, math.random())
    quantile.Reset(Quantile)
    quantile.Insert(Quantile, math.random())

    local res = quantile.Query(Quantile, 0.5)
    t.assert_not_equals(res, math.huge)
end

g.test_quantile_values_present_after_buffer_flush = function()
    local Quantile = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01}, 10)

    for _ = 1, 10 do
        quantile.Insert(Quantile, math.random())
    end

    t.assert(Quantile:flushed())
    -- buffer now is flushed

    local res = quantile.Query(Quantile, 0.5)
    t.assert_not_nan(res)
end
