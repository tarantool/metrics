local Shared = require('metrics.collectors.shared')

local Counter = {}
Counter.__index = Counter

function Counter.new(name, help, opts)
    opts = opts or {}
    if opts.do_register == nil then
        opts.do_register = true
    end

    local obj = Shared.new(name, help, 'counter')
    if opts.do_register then
        return global_metrics_registry:instanceof(obj, Counter)
    end
    return setmetatable(obj, Counter)
end

function Counter:inc(num, label_pairs)
    if num and num < 0 then
        error("Counter increment should not be negative")
    end
    Shared.inc(self, num, label_pairs)
end

function Counter:collect()
    return Shared.collect(self)
end

return Counter
