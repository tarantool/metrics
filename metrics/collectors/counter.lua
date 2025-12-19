local Shared = require('metrics.collectors.shared')

local Counter = Shared:new_class('counter', {'inc', 'reset'})

function Counter.Prepared:inc(num)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Counter increment should be a number")
    end
    if num and num < 0 then
        error("Counter increment should not be negative")
    end
    Shared.Prepared.inc(self, num)
end

function Counter.Prepared:reset()
    Shared.Prepared.set(self, 0)
end

return Counter
