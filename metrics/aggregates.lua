local default_kind_rules = {}

local rule_processors = {}

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