-- local ffi = require('ffi')
local utils = require('metrics.utils')
local psutils = require('metrics.psutils.psutils_linux')

local collectors_list = {}

local sys_mem_page_size
if jit.os == 'Linux' then
    local handler = io.popen("getconf PAGESIZE 2>&1")
    local output = handler:read("*a")
    handler:close()
    if output then
        sys_mem_page_size = tonumber(output)
    end
end

local function update_memory_metrics()
    if not utils.box_is_configured() then
        return
    end

    if box.info.memory ~= nil then
        local i = box.info.memory()
        for k, v in pairs(i) do
            local metric_name = 'info_memory_' .. k
            collectors_list[metric_name] = utils.set_gauge(metric_name, 'Memory ' .. k, v,
                nil, nil, {default = true})
        end
    end

    local memory_stat = 0
    local memory_virt_stat = 0

    if jit.os == 'Linux' then
        local data = psutils.get_process_stats()
        if data then
            memory_stat = data.rss * sys_mem_page_size
            memory_virt_stat = data.vsize
        end
    else
        --[[memory]]
        -- Skip `memory_box.data` cause in fact this is `memory_box.index`
        -- and `memory_box.cache` cause in fact this is `vinyl_stat.memory.tuple_cache`.
        if box.info.memory ~= nil then
            local memory_box = box.info.memory()
            for _, value in pairs(memory_box) do
                memory_stat = memory_stat + value
            end
        end

        --[[memtx]]
        local ok, memtx_stat_3 = pcall(box.stat.memtx)
        if ok then
            if memtx_stat_3.data ~= nil then
                memory_stat = memory_stat + memtx_stat_3.data.total
            end
            if memtx_stat_3.index ~= nil then
                memory_stat = memory_stat + memtx_stat_3.index.total
            end
        end

        --[[vinyl]]
        local vinyl_stat = box.stat.vinyl()
        if vinyl_stat ~= nil then
            memory_stat = memory_stat + vinyl_stat.memory.tuple_cache
                + vinyl_stat.memory.level0 + vinyl_stat.memory.page_index
                + vinyl_stat.memory.bloom_filter
            if vinyl_stat.memory.tuple ~= nil then
                memory_stat = memory_stat + vinyl_stat.memory.tuple
            end
        end
    end

    --[[metric]]
    collectors_list.memory_stat_usage = utils.set_gauge('memory',
        'Tarantool instance memory usage', memory_stat,
        nil, nil, {default = true})

    collectors_list.memory_virt_stat_usage = utils.set_gauge('memory_virt',
        'Tarantool instance virtual memory usage', memory_virt_stat,
        nil, nil, {default = true})
end

return {
    update = update_memory_metrics,
    list = collectors_list,
}
