local quantile = require('metrics.quantile')
local fiber = require('fiber')

local t = require('luatest')
local g = t.group('quantile-fiber')


local q = quantile.NewTargeted({[0.5]=0.01, [0.9]=0.01, [0.99]=0.01})


g.test_fiber = function()
    for i=1,1e6 do quantile.Insert(q, math.random(1)) end

    local fs = {}
    for i=1,200 do 
        local f = fiber.new(function()
            for i=1,1e3 do quantile.Insert(q, math.random(1000)) end
        end)
        f:set_joinable(true)
        table.insert(fs, f)
    end

    for i=1,1e3 do quantile.Insert(q, math.random(1000)) end

    for _, f in ipairs(fs) do
        f:join()
    end
end
