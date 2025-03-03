local metrics = require 'override.metrics'
local luahist = assert(metrics.histogram, 'no histogram')
local rusthist = assert(metrics.histogram_vec, 'no histogram_vec')

local M = {}

do
    local lh = luahist('no_labels', 'histogram')
    local rh = rusthist('rust_no_labels', 'histogram')
    local random = math.random

    ---@param b luabench.B
    function M.bench_001_no_labels_001_observe(b)
        b:run("histogram:observe", function(sb)
            for _ = 1, sb.N do lh:observe(random()) end
        end)
        b:run("histogram_vec:observe", function(sb)
            for _ = 1, sb.N do rh:observe(random()) end
        end)
    end

    ---@param b luabench.B
    function M.bench_001_no_labels_002_collect(b)
        b:run("histogram:collect", function(sb)
            for _ = 1, sb.N do lh:collect() end
        end)
        b:run("histogram_vec:collect", function(sb)
            for _ = 1, sb.N do rh:collect() end
        end)
        b:run("histogram_vec:collect_str", function(sb)
            for _ = 1, sb.N do rh:collect_str() end
        end)
    end
end

do
    local lh = luahist('one_label', 'histogram')
    local rh = rusthist('rust_one_label', 'histogram', {'status'})
    local random = math.random

    ---@param b luabench.B
    function M.bench_002_one_label_001_observe(b)
        b:run("histogram:observe", function(sb)
            for _ = 1, sb.N do
                local x = random()
                lh:observe(x, {status = x < 0.99 and 'ok' or 'fail'})
            end
        end)
        b:run("histogram_vec:observe", function(sb)
            for _ = 1, sb.N do
                local x = random()
                rh:observe(x, {status = x < 0.99 and 'ok' or 'fail'})
            end
        end)
    end

    ---@param b luabench.B
    function M.bench_002_one_label_002_collect(b)
        b:run("histogram:collect", function(sb)
            for _ = 1, sb.N do lh:collect() end
        end)
        b:run("histogram_vec:collect", function(sb)
            for _ = 1, sb.N do rh:collect() end
        end)
        b:run("histogram_vec:collect_str", function(sb)
            for _ = 1, sb.N do rh:collect_str() end
        end)
    end
end

do
    local rs = require('override.metrics.rs')
    function M.bench_003_rust_gather(b)
        for _ = 1, b.N do
            rs.gather()
        end
    end

    function M.bench_003_lua_gather(b)
        for _ = 1, b.N do
            local result = {}
            for _, c in pairs(metrics.registry.collectors) do
                if not c.collect_str then
                    for _, obs in ipairs(c:collect()) do
                        table.insert(result, obs)
                    end
                end
            end
        end
    end
end

return M
