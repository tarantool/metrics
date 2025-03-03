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
    local lh = luahist('two_labels', 'histogram')
    local rh = rusthist('rust_two_labels', 'histogram', {'status', 'method'})
    local random = math.random

    local methods = {'GET', 'POST', 'PUT', 'DELETE'}

    ---@param b luabench.B
    function M.bench_002_two_labels_001_observe(b)
        b:run("histogram:observe", function(sb)
            for _ = 1, sb.N do
                local x = random()
                lh:observe(x, {status = x < 0.99 and 'ok' or 'fail', method = methods[random(1, 4)]})
            end
        end)
        b:run("histogram_vec:observe", function(sb)
            for _ = 1, sb.N do
                local x = random()
                rh:observe(x, {status = x < 0.99 and 'ok' or 'fail', method = methods[random(1, 4)]})
            end
        end)
    end

    ---@param b luabench.B
    function M.bench_002_two_labels_002_collect(b)
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
    local lh = luahist('three_labels', 'histogram')
    local rh = rusthist('rust_three_labels', 'histogram', {'status', 'method', 'func'})
    local random = math.random

    local methods = {'GET', 'POST', 'PUT', 'DELETE'}
    local funcs = {
        'api.pet.find_by_status',
        'api.pet.find_by_id',
        'api.pet.get',
        'api.pet.find_by_tags',
        'api.pet.post',
        'api.pet.put',
        'api.pet.delete',
        'api.store.inventory.get',
        'api.store.order.post',
        'api.store.order.get',
        'api.store.order.delete',
        'api.user.get',
        'api.user.put',
        'api.user.delete',
        'api.user.post',
        'api.user.login',
        'api.user.logout',
    }
    local n_funcs = #funcs

    ---@param b luabench.B
    function M.bench_003_three_labels_001_observe(b)
        b:run("histogram:observe", function(sb)
            for _ = 1, sb.N do
                local x = random()
                lh:observe(x, {
                    status = x < 0.99 and 'ok' or 'fail',
                    method = methods[random(1, 4)],
                    func = funcs[random(1, n_funcs)],
                })
            end
        end)
        b:run("histogram_vec:observe", function(sb)
            for _ = 1, sb.N do
                local x = random()
                rh:observe(x, {
                    status = x < 0.99 and 'ok' or 'fail',
                    method = methods[random(1, 4)],
                    func = funcs[random(1, n_funcs)],
                })
            end
        end)
    end

    ---@param b luabench.B
    function M.bench_003_three_labels_002_collect(b)
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
    function M.bench_004_rust_gather(b)
        for _ = 1, b.N do
            rs.gather()
        end
    end

    function M.bench_004_lua_gather(b)
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
