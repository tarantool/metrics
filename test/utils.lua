local t = require('luatest')

local fun = require('fun')
local metrics = require('metrics')

local luatest_utils = require('luatest.utils')

local utils = {}

function utils.create_server(g)
    g.server = t.Server:new({
        alias = 'myserver',
        env = {
            LUA_PATH = utils.LUA_PATH,
            LUA_CPATH = utils.LUA_CPATH,
        }
    })
    g.server:start{wait_until_ready = true}
end

function utils.drop_server(g)
    g.server:drop()
end

function utils.find_obs(metric_name, label_pairs, observations, comparator)
    comparator = comparator or t.assert_equals

    for _, obs in pairs(observations) do
        local same_label_pairs = pcall(comparator, obs.label_pairs, label_pairs)
        if obs.metric_name == metric_name and same_label_pairs then
            return obs
        end
    end
    t.assert_items_include(observations, {metric_name = metric_name, label_pairs = label_pairs},
        'Missing observation')
end

function utils.observations_without_timestamps(observations)
    return fun.iter(observations or metrics.collect()):
        map(function(x)
            x.timestamp = nil
            return x
        end):
        totable()
end

function utils.assert_observations(actual, expected)
    t.assert_items_equals(
        utils.observations_without_timestamps(actual),
        fun.iter(expected):map(function(x)
            return {
                metric_name = x[1],
                value = x[2],
                label_pairs = x[3],
            }
        end):totable()
    )
end

function utils.find_metric(metric_name, metrics_data)
    local m = {}
    for _, v in ipairs(metrics_data) do
        if v.metric_name == metric_name then
            table.insert(m, v)
        end
    end
    return #m > 0 and m or nil
end

local function to_number_multiple(...)
    return unpack(fun.map(tonumber, {...}):totable())
end

function utils.is_version_less(ver_str, reference_ver_str)
    local major, minor, patch = to_number_multiple(string.match(ver_str, '^(%d+).(%d+).(%d+)'))
    local ref_major, ref_minor, ref_patch = to_number_multiple(string.match(reference_ver_str, '^(%d+).(%d+).(%d+)'))

    if ( major < ref_major ) or ( major == ref_major and minor < ref_minor) or
      ( major == ref_major and minor == ref_minor and patch < ref_patch) then
        return true
    else
        return false
    end
end

function utils.is_version_greater(ver_str, reference_ver_str)
    local major, minor, patch = to_number_multiple(string.match(ver_str, '^(%d+).(%d+).(%d+)'))
    local ref_major, ref_minor, ref_patch = to_number_multiple(string.match(reference_ver_str, '^(%d+).(%d+).(%d+)'))

    if ( major > ref_major ) or ( major == ref_major and minor > ref_minor) or
      ( major == ref_major and minor == ref_minor and patch > ref_patch) then
        return true
    else
        return false
    end
end

function utils.len(tbl)
    local l = 0
    for _ in pairs(tbl) do
        l = l + 1
    end
    return l
end

function utils.clear_spaces()
    for _, v in pairs(box.space) do
        if v.id > box.schema.SYSTEM_ID_MAX then
            v:drop()
        end
    end
end

function utils.is_tarantool_3_config_supported()
    local tarantool_version = luatest_utils.get_tarantool_version()
    return luatest_utils.version_ge(tarantool_version, luatest_utils.version(3, 0, 0))
end

-- Empty by default. Empty LUA_PATH satisfies built-in package tests.
-- For tarantool/metrics, LUA_PATH, LUA_CPATH are set up through test.helper
utils.LUA_PATH = nil
utils.LUA_CPATH = nil

return utils
