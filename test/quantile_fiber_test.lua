local quantile = require('metrics.quantile')
local fiber = require('fiber')

local t = require('luatest')
local g = t.group('quantile-fiber')


local q = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})


g.test_fiber = function()
    for i=1,1000 do quantile.Insert(q, math.random(1)) end
end
