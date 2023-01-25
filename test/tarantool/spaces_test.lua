require('strict').on()

local t = require('luatest')
local g = t.group()

local metrics = require('metrics')
local fun = require('fun')
local utils = require('test.utils')

g.before_each(function()
    rawset(_G, 'include_vinyl_count', true)

    utils.init()
    utils.clear_spaces()

    for _, engine in ipairs({'memtx', 'vinyl'}) do
        for i = 1, 3 do
            local space_name = engine .. '_space_' .. tostring(i)
            local s = box.schema.space.create(space_name, {engine = engine})
            for j = 1, 3 do
                s:create_index('index_' .. tostring(j))
            end
        end
    end

    metrics.enable_default_metrics()
end)

g.after_each(function()
    -- Delete all collectors and global labels
    metrics.clear()
    utils.clear_spaces()
    rawset(_G, 'include_vinyl_count', false)
end)

local function get_space_metrics(metric_name)
    return fun.iter(metrics.collect{invoke_callbacks = true}):filter(function(x)
        return x.metric_name:find(metric_name)
    end):map(function(m) return m.label_pairs end):totable()
end

g.test_spaces = function()
    local metrics_list = get_space_metrics('tnt_space')

    t.assert_items_include(metrics_list, {
        {engine = 'memtx', name = 'memtx_space_1'},
        {engine = 'memtx', name = 'memtx_space_2'},
        {engine = 'memtx', name = 'memtx_space_3'},
    })

    metrics_list = get_space_metrics('tnt_vinyl_tuples')
    t.assert_items_include(metrics_list, {
        {engine = 'vinyl', name = 'vinyl_space_1'},
        {engine = 'vinyl', name = 'vinyl_space_2'},
        {engine = 'vinyl', name = 'vinyl_space_3'},
    })
end

g.test_indexes = function()
    local metrics_list = get_space_metrics('tnt_space')

    t.assert_items_include(metrics_list, {
        {index_name = 'index_1', name = 'memtx_space_1'},
        {index_name = 'index_2', name = 'memtx_space_1'},
        {index_name = 'index_3', name = 'memtx_space_1'},
    })
    t.assert_items_include(metrics_list, {
        {index_name = 'index_1', name = 'vinyl_space_1'},
        {index_name = 'index_2', name = 'vinyl_space_2'},
        {index_name = 'index_3', name = 'vinyl_space_3'},
    })
end

g.test_disable_vinyl = function()
    local metrics_list = get_space_metrics('tnt_vinyl_tuples')

    t.assert_items_include(metrics_list, {
        {engine = 'vinyl', name = 'vinyl_space_1'},
        {engine = 'vinyl', name = 'vinyl_space_2'},
        {engine = 'vinyl', name = 'vinyl_space_3'},
    })

    local metrics_vinyl_index = get_space_metrics('tnt_space_index_bsize')

    t.assert_items_include(metrics_vinyl_index, {
        {index_name = 'index_1', name = 'vinyl_space_1'},
        {index_name = 'index_2', name = 'vinyl_space_2'},
        {index_name = 'index_3', name = 'vinyl_space_3'},
    })

    rawset(_G, 'include_vinyl_count', false)

    metrics_list = get_space_metrics('tnt_space')

    -- There is no "assert_items_not_include" function.
    local count = 0
    for _, item in pairs(metrics_list) do
        if item.engine == 'vinyl' and item.name ~= nil and item.name:startswith('vinyl_space') then
            count = count + 1
        end
    end
    t.assert_equals(count, 0)

    -- Doesn't affect vinyl indexes
    t.assert_items_include(metrics_list, {
        {index_name = 'index_1', name = 'vinyl_space_1'},
        {index_name = 'index_2', name = 'vinyl_space_2'},
        {index_name = 'index_3', name = 'vinyl_space_3'},
    })
end

g.test_drop_indexes = function()
    local metrics_list = get_space_metrics('tnt_space')

    t.assert_items_include(metrics_list, {
        {index_name = 'index_1', name = 'memtx_space_1'},
        {index_name = 'index_2', name = 'memtx_space_1'},
        {index_name = 'index_3', name = 'memtx_space_1'},
    })
    t.assert_items_include(metrics_list, {
        {index_name = 'index_1', name = 'vinyl_space_1'},
        {index_name = 'index_2', name = 'vinyl_space_2'},
        {index_name = 'index_3', name = 'vinyl_space_3'},
    })

    local count = 0
    for _, item in pairs(metrics_list) do
        if item.index_name ~= nil then
            count = count + 1
        end
    end
    t.assert_equals(count, 18)

    box.space.memtx_space_1.index.index_2:drop()
    box.space.memtx_space_2.index.index_2:drop()
    box.space.memtx_space_3.index.index_2:drop()

    box.space.vinyl_space_1.index.index_3:drop()
    box.space.vinyl_space_2.index.index_3:drop()
    box.space.vinyl_space_3.index.index_3:drop()

    metrics_list = get_space_metrics('tnt_space')
    count = 0
    for _, item in pairs(metrics_list) do
        if item.index_name ~= nil then
            count = count + 1
        end
    end
    t.assert_equals(count, 12)

    t.assert_items_include(metrics_list, {
        {index_name = 'index_1', name = 'memtx_space_1'},
        {index_name = 'index_3', name = 'memtx_space_1'},
        {index_name = 'index_1', name = 'memtx_space_2'},
        {index_name = 'index_3', name = 'memtx_space_2'},
        {index_name = 'index_1', name = 'memtx_space_3'},
        {index_name = 'index_3', name = 'memtx_space_3'},
    })
    t.assert_items_include(metrics_list, {
        {index_name = 'index_1', name = 'vinyl_space_1'},
        {index_name = 'index_2', name = 'vinyl_space_1'},
        {index_name = 'index_1', name = 'vinyl_space_2'},
        {index_name = 'index_2', name = 'vinyl_space_2'},
        {index_name = 'index_1', name = 'vinyl_space_3'},
        {index_name = 'index_2', name = 'vinyl_space_3'},
    })
end

g.test_drop_spaces = function()
    local metrics_list = get_space_metrics('tnt_space')

    t.assert_items_include(metrics_list, {
        {engine = 'memtx', name = 'memtx_space_1'},
        {engine = 'memtx', name = 'memtx_space_2'},
        {engine = 'memtx', name = 'memtx_space_3'},
    })

    local metrics_list_vinyl = get_space_metrics('tnt_vinyl_tuples')

    t.assert_items_include(metrics_list_vinyl, {
        {engine = 'vinyl', name = 'vinyl_space_1'},
        {engine = 'vinyl', name = 'vinyl_space_2'},
        {engine = 'vinyl', name = 'vinyl_space_3'},
    })

    local count = 0
    for _, item in pairs(metrics_list) do
        if item.engine ~= nil then
            count = count + 1
        end
    end
    for _, item in pairs(metrics_list_vinyl) do
        if item.engine ~= nil then
            count = count + 1
        end
    end
    t.assert_equals(count, 12)

    box.space.memtx_space_2:drop()

    box.space.vinyl_space_1:drop()
    box.space.vinyl_space_3:drop()

    metrics_list = get_space_metrics('tnt_space')
    count = 0
    for _, item in pairs(metrics_list) do
        if item.engine ~= nil then
            count = count + 1
        end
    end
    metrics_list_vinyl = get_space_metrics('tnt_vinyl_tuples')
    for _, item in pairs(metrics_list_vinyl) do
        if item.engine ~= nil then
            count = count + 1
        end
    end
    t.assert_equals(count, 7)

    t.assert_items_include(metrics_list, {
        {engine = 'memtx', name = 'memtx_space_1'},
        {engine = 'memtx', name = 'memtx_space_3'},
    })

    t.assert_items_include(metrics_list_vinyl, {
        {engine = 'vinyl', name = 'vinyl_space_2'},
    })
end
