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

local function get_gauge_example(timestamp, value1, value2)
    local res = {
        lj_gc_memorygauge = {
            name = 'lj_gc_memory',
            name_prefix = 'lj_gc_memory',
            kind = 'gauge',
            help = 'Memory currently allocated',
            metainfo = { default = true },
            timestamp = timestamp,
            observations = { [''] = {} }
        }
    }

    if value1 ~= nil then
        res['lj_gc_memorygauge'].observations[''][''] = {
            label_pairs = { alias = 'router' },
            value = value1,
        }
    end

    if value2 ~= nil then
        res['lj_gc_memorygauge'].observations['']['source\tvinyl_procedures'] = {
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

local function assert_extremums(output_with_aggregates, timestamp, min1, min2, max1, max2)
    t.assert_equals(utils.len(output_with_aggregates), 3,
        "Min and max computed for a single observation")

    local min_obs = output_with_aggregates['lj_gc_memory_mingauge']
    t.assert_not_equals(min_obs, nil, "min computed")
    t.assert_equals(min_obs.name, 'lj_gc_memory_min')
    t.assert_equals(min_obs.name_prefix, 'lj_gc_memory')
    t.assert_equals(min_obs.kind, 'gauge')
    t.assert_equals(min_obs.help, 'Minimum of lj_gc_memory')
    t.assert_equals(min_obs.metainfo.default, true)
    t.assert_equals(min_obs.timestamp, timestamp)
    t.assert_equals(min_obs.observations[''][''].label_pairs, { alias = 'router' })
    t.assert_almost_equals(min_obs.observations[''][''].value, min1)
    t.assert_equals(min_obs.observations['']['source\tvinyl_procedures'].label_pairs,
        { alias = 'router', source = 'vinyl_procedures' })
    t.assert_almost_equals(min_obs.observations['']['source\tvinyl_procedures'].value, min2)

    local max_obs = output_with_aggregates['lj_gc_memory_maxgauge']
    t.assert_not_equals(max_obs, nil, "max computed")
    t.assert_equals(max_obs.name, 'lj_gc_memory_max')
    t.assert_equals(max_obs.name_prefix, 'lj_gc_memory')
    t.assert_equals(max_obs.kind, 'gauge')
    t.assert_equals(max_obs.help, 'Maximum of lj_gc_memory')
    t.assert_equals(max_obs.metainfo.default, true)
    t.assert_equals(max_obs.timestamp, timestamp)
    t.assert_equals(max_obs.observations[''][''].label_pairs, { alias = 'router' })
    t.assert_almost_equals(max_obs.observations[''][''].value, max1)
    t.assert_equals(max_obs.observations['']['source\tvinyl_procedures'].label_pairs,
        { alias = 'router', source = 'vinyl_procedures' })
    t.assert_almost_equals(max_obs.observations['']['source\tvinyl_procedures'].value, max2)
end

g.test_gauge_extremums_no_previous_data = function()
    local output = get_gauge_example(1676364616294847ULL, 2020047, 327203)

    local output_with_aggregates = metrics.compute_aggregates(nil, output)

    assert_extremums(output_with_aggregates, 1676364616294847ULL, 2020047, 327203, 2020047, 327203)
end

g.test_gauge_extremums_prev_aggregates = function()
    local output_1 = get_gauge_example(1676364616294847ULL, 2020047, 327203)
    local output_2 = get_gauge_example(1676365196294847ULL, 1920047, 429203)

    local output_with_aggregates_1 = metrics.compute_aggregates(nil, output_1)
    local output_with_aggregates_2 = metrics.compute_aggregates(output_with_aggregates_1, output_2)

    assert_extremums(output_with_aggregates_2, 1676365196294847ULL, 1920047, 327203, 2020047, 429203)
end

g.test_gauge_extremums_prev_raw = function()
    local output_1 = get_gauge_example(1676364616294847ULL, 2020047, 327203)
    local output_2 = get_gauge_example(1676365196294847ULL, 1920047, 429203)

    local output_with_aggregates_2 = metrics.compute_aggregates(output_1, output_2)

    assert_extremums(output_with_aggregates_2, 1676365196294847ULL, 1920047, 327203, 2020047, 429203)
end

g.test_gauge_extremums_new_label = function()
    local output_1 = get_gauge_example(1676364616294847ULL, 2020047, nil)
    local output_2 = get_gauge_example(1676365196294847ULL, 1920047, 429203)

    local output_with_aggregates_1 = metrics.compute_aggregates(nil, output_1)
    local output_with_aggregates_2 = metrics.compute_aggregates(output_with_aggregates_1, output_2)
    t.assert_equals(utils.len(output_with_aggregates_2), 3,
        "Min and max computed for a single observation")

    assert_extremums(output_with_aggregates_2, 1676365196294847ULL, 1920047, 429203, 2020047, 429203)
end

g.test_gauge_min_max_disabled = function()
    local output_1 = get_counter_example(1676364616294847ULL, 14148, 3204)
    local output_2 = get_counter_example(1676364616294847ULL + 100 * 1e6, 14148 + 200, 3204 + 50)

    local opts = { gauge = {} }
    local output_with_aggregates_1 = metrics.compute_aggregates(nil, output_1, opts)
    local output_with_aggregates_2 = metrics.compute_aggregates(output_with_aggregates_1, output_2, opts)

    t.assert_equals(utils.len(output_with_aggregates_2), 1,
        "No min or max computed due to options")
end
