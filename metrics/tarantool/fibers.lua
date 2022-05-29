local fiber = require('fiber')
local utils = require('metrics.utils')

local collectors_list = {}

local function update_fibers_metrics()
    local fibers_info = fiber.info({backtrace = false})
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

    collectors_list.fiber_count = utils.set_gauge('fiber_count', 'Amount of fibers', fibers)
    collectors_list.fiber_amount = utils.set_gauge('fiber_amount', 'Amount of fibers', fibers)
    collectors_list.fiber_csw = utils.set_gauge('fiber_csw', 'Fibers csw', csws)
    collectors_list.fiber_memalloc = utils.set_gauge('fiber_memalloc', 'Fibers memalloc', falloc)
    collectors_list.fiber_memused = utils.set_gauge('fiber_memused', 'Fibers memused', fused)
end

return {
    update = update_fibers_metrics,
    list = collectors_list,
}
