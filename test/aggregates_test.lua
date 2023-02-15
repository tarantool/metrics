local t = require('luatest')

local g = t.group('metrics_aggregates')

local metrics = require('metrics')

local function get_counter_example(timestamp, value1, value2)
    local res = {
        lj_gc_steps_propagate_totalcounter = {
            name = 'lj_gc_steps_propagate_total',
            name_prefix = 'lj_gc_steps_propagate',
            kind = 'counter',
            help = 'Total count of incremental GC steps (propagate state)',
            metainfo = { default = true },
            timestamp = timestamp,
            observations = { [''] = {} },
        }
    }

    if value1 ~= nil then
        res['lj_gc_steps_propagate_totalcounter'].observations[''][''] = {
            label_pairs = { alias = 'router' },
            value = value1,
        }
    end

    if value2 ~= nil then
        res['lj_gc_steps_propagate_totalcounter'].observations['']['source\tvinyl_procedures'] = {
            label_pairs = { alias = 'router', source = 'vinyl_procedures' },
            value = value2,
        }
    end

    return res
end

g.test_unknown_rule = function()
    local output = get_counter_example(1676364616294847ULL, 14148, 3204)

    local opts = { counter = { 'per_hour_rate' }}
    t.assert_error_msg_contains('Unknown rule "per_hour_rate"',
        metrics.compute_aggregates, nil, output, opts)
end

g.test_no_rules = function()
    local output = get_counter_example(1676364616294847ULL, 14148, 3204)
    local original_output = table.deepcopy(output)
    t.assert_equals(metrics.compute_aggregates(nil, output), original_output)
end
