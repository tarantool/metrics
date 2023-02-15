local metrics = require('metrics')
local stash = require('metrics.stash')
local string_utils = require('metrics.string_utils')

local data_stash = stash.get('flight_recorder')

local function export()
    local output = metrics.collect{invoke_callbacks = true, extended_format = true}
    local output_with_aggregates = metrics.compute_aggregates(
        data_stash.output_with_aggregates_prev, output)
    data_stash.output_with_aggregates_prev = output_with_aggregates
    return output_with_aggregates
end

local function plain_format(output)
    local result = {}
    for _, coll_obs in pairs(output) do
        for group_name, obs_group in pairs(coll_obs.observations) do
            local metric_name = string_utils.build_name(coll_obs.name, group_name)
            for _, obs in pairs(obs_group) do
                local parts = {}
                for k, v in pairs(obs.label_pairs) do
                    table.insert(parts, k .. '=' .. v)
                end
                table.sort(parts)
                table.insert(result, string.format('%s{%s} %s',
                    metric_name,
                    table.concat(parts, ','),
                    obs.value
                ))
            end
        end
    end

    table.sort(result)
    return table.concat(result, '\n')
end

return {
    export = export,
    plain_format = plain_format,
}
