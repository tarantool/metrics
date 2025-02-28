local metrics = require 'override.metrics'
local luahist = assert(metrics.histogram, 'no histogram')
local rusthist = assert(metrics.histogram_vec, 'no histogram_vec')

local M = {}

do
    local lh = luahist('no_labels', 'histogram')
    local rh = rusthist('rust_no_labels', 'histogram')
    local random = math.random

    ---@param b luabench.B
    function M.bench_no_labels_001_observe(b)
        b:run("histogram:observe", function(sb)
            for _ = 1, sb.N do lh:observe(random()) end
        end)
        b:run("histogram_vec:observe", function(sb)
            for _ = 1, sb.N do rh:observe(random()) end
        end)
    end

    ---@param b luabench.B
    function M.bench_no_labels_002_collect(b)
        b:run("histogram:collect", function(sb)
            for _ = 1, sb.N do lh:collect() end
        end)
        b:run("histogram_vec:collect", function(sb)
            for _ = 1, sb.N do rh:collect() end
        end)
    end
end

do
    local lh = luahist('one_label', 'histogram')
    local rh = rusthist('rust_one_label', 'histogram', {'status'})
    local random = math.random

    ---@param b luabench.B
    function M.bench_one_label_001_observe(b)
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
    function M.bench_one_label_002_collect(b)
        b:run("histogram:collect", function(sb)
            for _ = 1, sb.N do lh:collect() end
        end)
        b:run("histogram_vec:collect", function(sb)
            for _ = 1, sb.N do rh:collect() end
        end)
    end
end

return M
