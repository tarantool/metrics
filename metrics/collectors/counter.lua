local Shared = require('metrics.collectors.shared')

---@class metrics.collector.counter : metrics.collector
local Counter = Shared:new_class('counter')

--- Increment the observation for `label_pairs`.
---@param num number?
---@param label_pairs metrics.label_pairs?
function Counter:inc(num, label_pairs)
    if num ~= nil and type(tonumber(num)) ~= 'number' then
        error("Counter increment should be a number")
    end
    if num and num < 0 then
        error("Counter increment should not be negative")
    end
    Shared.inc(self, num, label_pairs)
end

--- Set the observation for `label_pairs` to 0.
---@param label_pairs metrics.label_pairs?
function Counter:reset(label_pairs)
    Shared.set(self, 0, label_pairs)
end

return Counter
