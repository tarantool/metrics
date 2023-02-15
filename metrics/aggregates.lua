local string_utils = require('metrics.string_utils')
local Counter = require('metrics.collectors.counter')
local Gauge = require('metrics.collectors.gauge')

local mksec_in_sec = 1e6

local RATE_SUFFIX = 'per_second'

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


local default_kind_rules = {
    [Counter.kind] = { 'rate' },
}

local rule_processors = {
    rate = compute_counter_rate,
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