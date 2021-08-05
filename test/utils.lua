local t = require('luatest')

local fun = require('fun')
local metrics = require('metrics')
local fio = require('fio')

local utils = {}

local tempdir = fio.tempdir()
t.after_suite(function()
    fio.rmtree(tempdir)
end)

function utils.init()
    box.cfg{
        memtx_dir = tempdir,
        vinyl_dir = tempdir,
        wal_dir = tempdir,
    }
end

function utils.find_obs(metric_name, label_pairs, observations)
    for _, obs in pairs(observations) do
        local same_label_pairs = pcall(t.assert_equals, obs.label_pairs, label_pairs)
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

function utils.is_version_less(ver_str, reference_ver_str)
    local major, minor, patch = string.match(ver_str, '^(%d+).(%d+).(%d+)')
    local ref_major, ref_minor, ref_patch = string.match(reference_ver_str, '^(%d+).(%d+).(%d+)')

    if ( major < ref_major ) or ( major == ref_major and minor < ref_minor) or
      ( major == ref_major and minor == ref_minor and patch < ref_patch) then
        return true
    else
        return false
    end
end

function utils.is_version_greater(ver_str, reference_ver_str)
    local major, minor, patch = string.match(ver_str, '^(%d+).(%d+).(%d+)')
    local ref_major, ref_minor, ref_patch = string.match(reference_ver_str, '^(%d+).(%d+).(%d+)')

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

return utils
