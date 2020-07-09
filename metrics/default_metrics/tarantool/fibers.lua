local fiber = require('fiber')
local utils = require('metrics.utils')

local function update_fibers_metrics()
    local fibers_info = fiber.info()
    local fibers = 0
    local csws = 0
    local falloc = 0
    local fused = 0

    for _, f in pairs(fibers_info) do
        fibers = fibers + 1
        csws = csws + f.csw
        falloc = falloc + f.memory.total
        fused = fused + f.memory.used
    end

    utils.set_gauge('fiber_count', 'Amount of fibers', fibers)
    utils.set_gauge('fiber_csw', 'Fibers csw', csws)
    utils.set_gauge('fiber_memalloc', 'Fibers memalloc', falloc)
    utils.set_gauge('fiber_memused', 'Fibers memused', fused)
end

return {
    update = update_fibers_metrics,
}
