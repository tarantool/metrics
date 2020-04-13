local Shared = require('metrics.collectors.shared')

local Gauge = Shared:new_class('gauge', {'inc', 'dec', 'set'})

return Gauge
