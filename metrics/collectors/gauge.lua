local Shared = require('metrics.collectors.shared')

local Gauge = {}
Gauge.__index = Gauge

function Gauge.new(name, help)
    local obj = Shared.new(name, help, 'gauge')
    return global_metrics_registry:instanceof(obj, Gauge)
end

function Gauge:inc(num, label_pairs)
    Shared.inc(self, num, label_pairs)
end

function Gauge:dec(num, label_pairs)
    Shared.dec(self, num, label_pairs)
end

function Gauge:set(num, label_pairs)
    Shared.set(self, num, label_pairs)
end

function Gauge:collect()
    return Shared.collect(self)
end

return Gauge
