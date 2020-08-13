local quantile = require('metrics.quantile')
local t = require('luatest')
local g = t.group('quantile')

local q = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})

local function getPerc(x, p)
	local k = math.modf(#x * p)
	return x[k]
end

local x = {}
for i = 1,10^6 do
    local m = math.random()
    table.insert(x, m)
    quantile.Insert(q, m)
end

table.sort(x)

local function assert_quantile(quan)
    local w = getPerc(x, quan)
    local g = quantile.Query(q, quan)
    t.assert(math.abs(w-g)/w < 0.05, ('%f, %f, %f'):format(w, g, math.abs(w-g)/w))
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
