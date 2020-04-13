local Shared = require('metrics.collectors.shared')

local Counter = Shared:new_class('counter')

function Counter:inc(num, label_pairs)
    if num and num < 0 then
        error("Counter increment should not be negative")
    end
    Shared.inc(self, num, label_pairs)
end

return Counter
