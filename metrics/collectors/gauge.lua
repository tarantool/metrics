local Shared = require('metrics.collectors.shared')

---@class metrics.collector.gauge : metrics.collector
local Gauge = Shared:new_class('gauge', {'inc', 'dec', 'set'})

return Gauge
