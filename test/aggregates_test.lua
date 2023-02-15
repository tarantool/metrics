local t = require('luatest')

local g = t.group('metrics_aggregates')

local metrics = require('metrics')
local utils = require('test.utils')

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

g.test_counter_rate_no_previous_data = function()
    local output = get_counter_example(1676364616294847ULL, 14148, 3204)

    local output_with_aggregates = metrics.compute_aggregates(nil, output)
    t.assert_equals(utils.len(output_with_aggregates), 1,
        "No rate computed for a single observation")
end

g.test_counter_rate = function()
    local output_1 = get_counter_example(1676364616294847ULL, 14148, 3204)
    local output_2 = get_counter_example(1676364616294847ULL + 100 * 1e6, 14148 + 200, 3204 + 50)

    local output_with_aggregates_1 = metrics.compute_aggregates(nil, output_1)
    local output_with_aggregates_2 = metrics.compute_aggregates(output_with_aggregates_1, output_2)

    t.assert_equals(utils.len(output_with_aggregates_2), 2, "Rate computed")

    local rate_obs = output_with_aggregates_2['lj_gc_steps_propagate_per_secondgauge']
    t.assert_not_equals(rate_obs, nil, "Rate computed")
    t.assert_equals(rate_obs.name, 'lj_gc_steps_propagate_per_second')
    t.assert_equals(rate_obs.name_prefix, 'lj_gc_steps_propagate')
    t.assert_equals(rate_obs.kind, 'gauge')
    t.assert_equals(rate_obs.help, 'Average per second rate of change of lj_gc_steps_propagate_total')
    t.assert_equals(rate_obs.metainfo.default, true)
    t.assert_equals(rate_obs.timestamp, 1676364616294847ULL + 100 * 1e6)
    t.assert_equals(rate_obs.observations[''][''].label_pairs, { alias = 'router' })
    t.assert_almost_equals(rate_obs.observations[''][''].value, 200 / 100)
    t.assert_equals(rate_obs.observations['']['source\tvinyl_procedures'].label_pairs,
        { alias = 'router', source = 'vinyl_procedures' })
    t.assert_almost_equals(rate_obs.observations['']['source\tvinyl_procedures'].value, 50 / 100)
end

g.test_counter_rate_new_label = function()
    local output_1 = get_counter_example(1676364616294847ULL, 14148, nil)
    local output_2 = get_counter_example(1676364616294847ULL + 100 * 1e6, 14148 + 200, 3204)

    local output_with_aggregates_1 = metrics.compute_aggregates(nil, output_1)
    local output_with_aggregates_2 = metrics.compute_aggregates(output_with_aggregates_1, output_2)

    t.assert_equals(utils.len(output_with_aggregates_2), 2, "Rate computed")

    local rate_obs = output_with_aggregates_2['lj_gc_steps_propagate_per_secondgauge']
    t.assert_not_equals(rate_obs, nil, "Rate computed")
    t.assert_not_equals(rate_obs.observations[''][''], nil)
    t.assert_equals(rate_obs.observations['']['source\tvinyl_procedures'], nil)
end

g.test_counter_rate_wrong_timeline = function()
    local output_1 = get_counter_example(1676364616294847ULL, 14148, 3204)
    local output_2 = get_counter_example(1676364616294847ULL + 100 * 1e6, 14148 + 200, 3204 + 50)

    local output_with_aggregates_2 = metrics.compute_aggregates(nil, output_2)
    local output_with_aggregates_1 = metrics.compute_aggregates(output_with_aggregates_2, output_1)

    t.assert_equals(utils.len(output_with_aggregates_1), 1,
        "No rate computed for reverse observations timeline")
end

g.test_counter_rate_too_high_collect_rate = function()
    local output_1 = get_counter_example(1676364616294847ULL, 14148, 3204)
    local output_2 = get_counter_example(1676364616294847ULL, 14148 + 200, 3204 + 50)

    local output_with_aggregates_1 = metrics.compute_aggregates(nil, output_1)
    local output_with_aggregates_2 = metrics.compute_aggregates(output_with_aggregates_1, output_2)

    t.assert_equals(utils.len(output_with_aggregates_2), 1,
        "No rate computed if two observations are for the same time")
end

g.test_counter_rate_disabled = function()
    local output_1 = get_counter_example(1676364616294847ULL, 14148, 3204)
    local output_2 = get_counter_example(1676364616294847ULL + 100 * 1e6, 14148 + 200, 3204 + 50)

    local opts = { counter = {} }
    local output_with_aggregates_1 = metrics.compute_aggregates(nil, output_1, opts)
    local output_with_aggregates_2 = metrics.compute_aggregates(output_with_aggregates_1, output_2, opts)

    t.assert_equals(utils.len(output_with_aggregates_2), 1,
        "No rate computed due to options")
end
