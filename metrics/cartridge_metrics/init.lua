local metrics = require('metrics')

local cartridge_metrics = {
    require('metrics.cartridge_metrics.issues'),
}

local function enable()
    for _, metric in ipairs(cartridge_metrics) do
        metrics.register_callback(metric.update)
    end
end

return {
    enable = enable,
}
