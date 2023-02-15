local string_utils = require('metrics.string_utils')
local Counter = require('metrics.collectors.counter')
local Gauge = require('metrics.collectors.gauge')
local Histogram = require('metrics.collectors.histogram')
local Summary = require('metrics.collectors.summary')

-- Otherwise we need to implement different average processors.
assert(Histogram.SUM_SUFFIX == Summary.SUM_SUFFIX)
assert(Histogram.COUNT_SUFFIX == Summary.COUNT_SUFFIX)

local mksec_in_sec = 1e6

local RATE_SUFFIX = 'per_second'
local MIN_SUFFIX = 'min'
local MAX_SUFFIX = 'max'
local AVERAGE_SUFFIX = 'average'

local function compute_rate_value(time_delta, obs_prev, obs)
    if obs_prev == nil then
        return nil
    end

    return {
        label_pairs = obs.label_pairs,
        value = tonumber(obs.value - obs_prev.value) / (time_delta / mksec_in_sec)
    }
end

local function compute_counter_rate(output_with_aggregates_prev, output, coll_key, coll_obs)
    local name = string_utils.build_name(coll_obs.name_prefix, RATE_SUFFIX)
    local kind = Gauge.kind -- Derivative of monotonic is not monotonic.
    local registry_key = string_utils.build_registry_key(name, kind)

    if output[registry_key] ~= nil then
        -- If, for any reason, registry collision had happenned,
        -- we assume that there is already an aggregate metric with the
        -- similar meaning.
        return registry_key, output[registry_key]
    end

    local prev_coll_obs = output_with_aggregates_prev[coll_key]

    if prev_coll_obs == nil then
        return registry_key, nil
    end


    -- ULL subtraction on older Tarantools yields big ULL.
    if coll_obs.timestamp <= prev_coll_obs.timestamp then
        return registry_key, nil
    end

    -- tonumber to work with float deltas instead of cdata integers.
    local time_delta = tonumber(coll_obs.timestamp - prev_coll_obs.timestamp)

    if time_delta <= 0 then
        return registry_key, nil
    end

    local values = {}

    for key, obs in pairs(coll_obs.observations['']) do
        local obs_prev = prev_coll_obs.observations[''][key]
        values[key] = compute_rate_value(time_delta, obs_prev, obs)
    end

    return registry_key, {
        name = name,
        name_prefix = coll_obs.name_prefix,
        help = "Average per second rate of change of " .. coll_obs.name,
        kind = kind,
        metainfo = coll_obs.metainfo,
        timestamp = coll_obs.timestamp,
        observations = {[''] = values}
    }
end

local function compute_extremum_value(obs_prev, obs, method)
    if obs_prev == nil then
        return {
            label_pairs = obs.label_pairs,
            value = obs.value,
        }
    end

    return {
        label_pairs = obs.label_pairs,
        -- math.min and math.max doesn't work with cdata.
        value = method(tonumber(obs_prev.value), tonumber(obs.value))
    }
end

local function compute_gauge_extremum(output_with_aggregates_prev, output, coll_key, coll_obs,
                                      extremum_method, extremum_suffix, extremum_help_line)
    local name = string_utils.build_name(coll_obs.name_prefix, extremum_suffix)
    local kind = coll_obs.kind
    local registry_key = string_utils.build_registry_key(name, kind)

    if output[registry_key] ~= nil then
        -- If, for any reason, registry collision had happenned,
        -- we assume that there is already an aggregate metric with the
        -- similar meaning.
        return registry_key, output[registry_key]
    end

    local known_extremum
    if output_with_aggregates_prev[registry_key] then -- previous extremum
        known_extremum = output_with_aggregates_prev[registry_key]
    elseif output_with_aggregates_prev[coll_key] then -- previous value
        known_extremum = output_with_aggregates_prev[coll_key]
    else -- only current observation
        known_extremum = coll_obs
    end

    local values = {}

    for key, obs in pairs(coll_obs.observations['']) do
        local obs_prev = known_extremum.observations[''][key]
        values[key] = compute_extremum_value(obs_prev, obs, extremum_method)
    end

    return registry_key, {
        name = name,
        name_prefix = coll_obs.name_prefix,
        help = extremum_help_line .. coll_obs.name,
        kind = kind,
        metainfo = coll_obs.metainfo,
        timestamp = coll_obs.timestamp,
        observations = {[''] = values}
    }
end

local function compute_gauge_min(output_with_aggregates_prev, output, coll_key, coll_obs)
    return compute_gauge_extremum(output_with_aggregates_prev, output, coll_key, coll_obs,
                                  math.min, MIN_SUFFIX, "Minimum of ")
end

local function compute_gauge_max(output_with_aggregates_prev, output, coll_key, coll_obs)
    return compute_gauge_extremum(output_with_aggregates_prev, output, coll_key, coll_obs,
                                  math.max, MAX_SUFFIX, "Maximum of ")
end

local function compute_average_value(sum_obs, count_obs)
    -- For each sum there should be count, otherwise info is malformed.
    if sum_obs == nil then
        return nil
    end

    if count_obs.value == 0 then
        return {
            label_pairs = count_obs.label_pairs,
            value = 0,
        }
    end

    return {
        label_pairs = count_obs.label_pairs,
        -- Force to float division instead of possible cdata integer division.
        value = tonumber(sum_obs.value) / tonumber(count_obs.value),
    }
end

local function compute_collector_average(_, output, _, coll_obs)
    local name = string_utils.build_name(coll_obs.name_prefix, AVERAGE_SUFFIX)
    local kind = Gauge.kind
    local registry_key = string_utils.build_registry_key(name, kind)

    if output[registry_key] ~= nil then
        -- If, for any reason, registry collision had happenned,
        -- we assume that there is already an aggregate metric with the
        -- similar meaning.
        return registry_key, output[registry_key]
    end

    local values = {}

    for key, count_obs in pairs(coll_obs.observations[Histogram.COUNT_SUFFIX]) do
        local sum_obs = coll_obs.observations[Histogram.SUM_SUFFIX][key]
        values[key] = compute_average_value(sum_obs, count_obs)
    end

    return registry_key, {
        name = name,
        name_prefix = coll_obs.name_prefix,
        help = "Average value (over all time) of " .. coll_obs.name,
        kind = kind,
        metainfo = coll_obs.metainfo,
        timestamp = coll_obs.timestamp,
        observations = {[''] = values}
    }
end

local default_kind_rules = {
    [Counter.kind] = { 'rate' },
    [Gauge.kind] = { 'min', 'max' },
    [Histogram.kind] = { 'average' },
    [Summary.kind] = { 'average' },
}

local rule_processors = {
    rate = compute_counter_rate,
    min = compute_gauge_min,
    max = compute_gauge_max,
    average = compute_collector_average,
}

local function compute(output_with_aggregates_prev, output, kind_rules)
    output_with_aggregates_prev = output_with_aggregates_prev or {}
    kind_rules = kind_rules or default_kind_rules

    -- Iterating through table and adding new keys may result in skipping some keys.
    local output_with_aggregates = table.deepcopy(output)

    for coll_key, coll_obs in pairs(output) do
        local coll_rules = kind_rules[coll_obs.kind] or {}
        for _, rule in ipairs(coll_rules) do
            if rule_processors[rule] == nil then
                error(("Unknown rule %q"):format(rule))
            end

            local k, v = rule_processors[rule](output_with_aggregates_prev, output, coll_key, coll_obs)
            output_with_aggregates[k] = v
        end
    end

    return output_with_aggregates
end

return {
    compute = compute,
}