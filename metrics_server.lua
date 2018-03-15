--- Metrics Server

require('details.validation')

local expirationd = require('expirationd')
local log = require('log')
local json = require('json')
local fiber = require('fiber')

local INF = math.huge
local NAN = math.huge * 0

local function init()
    box.once('bootstrap_metrics_server', function ()
        -- (metric_name, label_pairs) -> labels_id
        local labels = box.schema.space.create('labels')
        labels:format {
            {name = 'labels_id', type = 'unsigned'},
            {name = 'metric_name', type = 'string'},
            {name = 'label_pairs'},
        }
        labels:create_index('primary', {
            parts = {'labels_id'},
        })
        labels:create_index('by_metric_name', {
            unique = false,
            parts = {'metric_name'},
        })

        -- (metric_name, labels_id) -> ts_id
        local metrics = box.schema.space.create('metrics')
        metrics:format {
            {name = 'metric_name', type = 'string'},
            {name = 'labels_id', type = 'unsigned'},
            {name = 'ts_id', type = 'unsigned'},
        }
        metrics:create_index('primary', {
            parts = {'metric_name', 'labels_id'},
        })

        -- timeserieses (mm, is it grammatically correct?)
        -- (ts_id) -> list of (timestamp, observation) pairs
        local observations = box.schema.space.create('observations')
        observations:format {
            {name = 'obs_id', type = 'unsigned'},
            {name = 'ts_id', type = 'unsigned'},
            {name = 'order_in_ts', type = 'unsigned'},
            {name = 'observation'},
            {name = 'timestamp', type = 'unsigned'},
        }
        observations:create_index('primary', {
            parts = {'obs_id'},
        })
        observations:create_index('by_ts_id', {
            unique = false,
            parts = {'ts_id', 'timestamp'},
        })

        -- sequences for generating label ids and timeseries ids
        _ = box.schema.sequence.create('gen_labels_id')
        _ = box.schema.sequence.create('gen_ts_id')
    end)
end

-- is a subtable of b?
local function is_subtable(a, b)
    for k, v in pairs(a) do
        if b[k] ~= v then
            return false
        end
    end
    return true
end

local function tables_equal(a, b)
    return is_subtable(a, b) and is_subtable(b, a)
end

local function match_label_pairs(metric_name, label_pairs)
    local result = {}
    local index = box.space.labels.index.by_metric_name
    for _, tuple in index:pairs(metric_name) do
        if is_subtable(label_pairs, tuple.label_pairs) then
            table.insert(result, tuple.label_pairs)
        end
    end
    return result
end

local function get_label_id(metric_name, label_pairs)
    local index = box.space.labels.index.by_metric_name
    for _, tuple in index:pairs(metric_name) do
        if tables_equal(label_pairs, tuple.label_pairs) then
            return tuple.labels_id
        end
    end
    local fmt = 'no labels_id for (metric_name = %s, label_pairs = %s)'
    return nil, string.format(fmt, metric_name, json.encode(label_pairs))
end

local function timeseries_id(metric_name, label_pairs, create_if_not_exists)
    metric_name = metric_name or ''
    label_pairs = label_pairs or {}

    -- get or create id for label values
    local labels_id, err = get_label_id(metric_name, label_pairs)
    if not labels_id then
        if create_if_not_exists then
            labels_id = box.sequence.gen_labels_id:next()
            box.space.labels:insert{labels_id, metric_name, label_pairs}
        else
            return nil, err
        end
    end

    -- get or create id of timeseries
    local tuple = box.space.metrics:get{metric_name, labels_id}
    if not tuple then
        if create_if_not_exists then
            local ts_id = box.sequence.gen_labels_id:next()
            tuple = box.space.metrics:insert{metric_name, labels_id, ts_id}
        else
            local fmt = 'not found timeseries for (metric_name = %s, label_pairs = %s)'
            return nil, string.format(fmt, metric_name, json.encode(label_pairs))
        end
    end

    return tuple.ts_id
end

------------------------------ MONITORING FUNCTIONS --------------------------

local function metrics_list()
    local result = {}
    for _, tuple in pairs(box.space.labels:select()) do
        table.insert(result, {
            metric_name = tuple.metric_name,
            label_pairs = tuple.label_pairs
        })
    end
    return result
end

local function metric(metric_name, label_pairs)
    local ts_id, err = timeseries_id(metric_name, label_pairs)
    if not ts_id then
        log.info('get_metric_ts: %s', err)
        return nil
    end

    local result = {}
    local index = box.space.observations.index.by_ts_id
    for _, tuple in index:pairs(ts_id) do
        table.insert(result, tuple)
    end
    return result
end

------------------------------ CLIENT ENTRY ----------------------------------

local function next_order(ts_id)
    local last = box.space.observations.index.by_ts_id:max(ts_id)
    if last and last.ts_id ~= ts_id then
        last = nil
    end
    return last and last.order_in_ts + 1 or 1
end

local function add_observation_impl(obs)
    local ts_id = timeseries_id(obs.metric_name, obs.label_pairs, true)
    box.space.observations:auto_increment{
        ts_id,
        next_order(ts_id),
        obs.value,
        obs.timestamp
    }
    log.info('Observation inserted!')
end

local function add_observation(obs)
    checks {
        metric_name = {type = 'string'},
        label_pairs = {default = {}},
        value = {type = 'number'},
        timestamp = {type = 'cdata'},  -- fiber.time64() returns cdata
    }

    local ok, status = xpcall(
        add_observation_impl,
        function (x)
            log.info('Exception catched: %s', x)
            log.info('Traceback: ' .. debug.traceback())
        end,
        obs
    )
    return ok, status
end

---------------------------- TIMESERIESS MANIPULATION ------------------------

local function map_vector(vec, map_func)
    for _, timeseries in pairs(vec.timeseriess) do
        for _, obs_pair in pairs(timeseries.observations) do
            obs_pair[1] = map_func(obs_pair[1])
        end
    end
    return vec
end

local vector_mt = {}
function vector_mt.__add(a, b)
    if type(b) == 'number' then
        map_vector(a, function (observation) return observation + b end)
        return a
    else
        return nil
    end
end
function vector_mt.__unm(a, b)
    if type(b) == 'number' then
        map_vector(a, function (observation) return -observation end)
        return a
    else
        return nil
    end
end
function vector_mt.__sub(a, b)
    if type(b) == 'number' then
        map_vector(a, function (observation) return observation - b end)
        return a
    else
        return nil
    end
end
function vector_mt.__pow(a, b)
    if type(b) == 'number' then
        map_vector(a, function (observation) return observation ^ b end)
        return a
    else
        return nil
    end
end
function vector_mt.__concat(a, b)
    error('Not implemented')
end
function vector_mt.__mul(a, b)
    if type(b) == 'number' then
        map_vector(a, function (observation) return observation * b end)
        return a
    else
        return nil
    end
end
function vector_mt.__div(a, b)
    if type(b) == 'number' then
        map_vector(a, function (observation) return observation / b end)
    else
        return a
    end
end

local function instant_timeseries(ts_id, metric_name, label_pairs)
    -- most recent observation in timeseries
    local observations = {}
    local tuple = box.space.observations.index.by_ts_id:max(ts_id)
    if tuple.ts_id == ts_id then
        table.insert(observations, {
            tuple.observation,
            tuple.timestamp
        })
    end

    -- timeseries
    return {
        observations = observations,
        label_pairs = label_pairs,
        metric_name = metric_name,
    }
end

local function range_timeseries(ts_id, metric_name, label_pairs, past)
    -- observations in timeseries for `past` seconds
    local observations = {}
    local timestamp_min = fiber.time64() - past

    local index = box.space.observations.index.by_ts_id
    for _, tuple in index:pairs({ts_id, timestamp_min}, {iterator = 'GT'}) do
        if tuple.ts_id ~= ts_id then
            break
        end
        table.insert(observations, {
            tuple.observation,
            tuple.timestamp
        })
    end

    -- timeseries
    return {
        observations = observations,
        label_pairs = label_pairs,
        metric_name = metric_name,
    }
end

-- Instant vector, if past == nil
-- Range vector, otherwise
--
-- XXX: introduce label filtering (more than one timeseries)
local function vector(metric_name, label_pairs, past)
    metric_name = metric_name or ''
    label_pairs = label_pairs or {}
    past = past

    local is_range = past ~= nil

    local obj = {}
    obj.timeseriess = {}

    -- add timeseriess for all label sets which are supersets of label_pairs
    local matched = match_label_pairs(metric_name, label_pairs)
    for _, matched_label_pairs in pairs(matched) do
        local ts_id = timeseries_id(metric_name, matched_label_pairs)

        local timeseries = is_range and
            range_timeseries(ts_id, metric_name, matched_label_pairs, past) or
            instant_timeseries(ts_id, metric_name, matched_label_pairs)

        table.insert(obj.timeseriess, timeseries)
    end

    if is_range then
        obj.range_end = fiber.time64()
        obj.range_start = obj.range_end - past
    end

    return setmetatable(obj, vector_mt)
end

-- range vector aggregation
local function avg_over_time(vec)
    for _, timeseries in pairs(vec.timeseriess) do
        local count = 0
        local sum = 0
        for _, obs_pair in pairs(timeseries.observations) do
            count = count + 1
            sum = sum + obs_pair[1]
        end
        local avg = sum / count
        timeseries.observations = {{avg, NAN}}
    end
    return vec
end

-- aggregators
local function sum(vec, by)
    error('Not implemented')
end

-- miscallaneous
local function irate(vec)
    for _, timeseries in pairs(vec.timeseriess) do
        -- take last 2 observations and make rate
        local last_obs = timeseries.observations[#timeseries.observations]
        local before_last_obs = timeseries.observations[#timeseries.observations - 1]

        local instant_rate
        if last_obs == nil or before_last_obs == nil then
            instant_rate = nil
        else
            instant_rate = (last_obs[1] - before_last_obs[1]) / (last_obs[2] - before_last_obs[2])
            instant_rate = math.max(instant_rate, 0)
        end
        timeseries.observations = {{instant_rate, last_obs[2]}}
    end
    return vec
end

local function rate(vec)
    for _, timeseries in pairs(vec.timeseriess) do
        local total_increase = 0
        local start_range = nil
        local end_range = nil
        local last_obs = timeseries.observations[#timeseries.observations]

        local prev = INF
        for _, obs in pairs(timeseries.observations) do
            -- adjust for resets (negative deltas)
            if obs[1] >= prev then
                total_increase = total_increase + obs[1] - prev
            end
            prev = obs[1]
            start_range = start_range or obs[2]
            end_range = obs[2]
        end

        local result_rate = total_increase / (end_range - start_range)
        timeseries.observations = {{result_rate, last_obs[2]}}
    end
    return vec
end

local function increase(vec)
    for _, timeseries in pairs(vec.timeseriess) do
        local total_increase = 0
        local start_range = nil
        local end_range = nil
        local last_obs = timeseries.observations[#timeseries.observations]

        local prev = INF
        for _, obs in pairs(timeseries.observations) do
            -- adjust for resets (negative deltas)
            if obs[1] >= prev then
                total_increase = total_increase + obs[1] - prev
            end
            prev = obs[1]
            start_range = start_range or obs[2]
            end_range = obs[2]
        end

        -- calculate extrapolation coefficient to fit to time range
        -- (there maybe ommited observations to the left bound and to the right bound) 
        local extrapolation = 1
        do
            -- NOTE: Prometheus extrapolates more sophisticatedly:
            -- https://github.com/prometheus/prometheus/blob/c77c3a8c56cf72ffca212bd3d34c87cbf8bc772f/promql/functions.go#L78-L115
            local is_range = vec.range_start ~= nil
            if is_range then
                -- just amplify
                extrapolation = (vec.range_end - vec.range_start) / (end_range - start_range)
            end
        end

        timeseries.observations = {{extrapolation * total_increase, last_obs[2]}}
    end
    return vec
end

local function resets(vec)
    for _, timeseries in pairs(vec.timeseriess) do
        local resets_count = 0
        local prev = -INF
        local last_obs = timeseries.observations[#timeseries.observations]
        for _, obs in pairs(timeseries.observations) do
            if obs[1] < prev then
                resets_count = resets_count + 1
            end
            prev = obs[1]
        end
        timeseries.observations = {{resets_count, last_obs[2]}}
    end
    return vec
end

-- Comparison operator
-- Needed for sorting histogram timeseriess by buckets
-- (`le` label specifies bucket)
local function bucket_comparator(a_ts, b_ts)
    local a_bucket = a_ts.label_pairs['le']
    local b_bucket = b_ts.label_pairs['le']
    return a_bucket < b_bucket
end

function checkers.percent(phi)
    return type(phi) == 'number' and 0.0 <= phi and phi <= 1.0
end

function checkers.histogram_vector(vec)
    if type(vec) ~= 'table' then return false end
    if not vec.timeseriess then return false end
    for i, timeseries in pairs(vec.timeseriess) do
        if not timeseries.label_pairs then return false end
        if type(timeseries.label_pairs['le']) ~= 'number' then
            return false
        end
    end
    return true
end

--- Approximate percentile given histogram
--
--  @param vec  Range vector or metric name
--  @param phi  Percentage for percentile (e.g. 0.99 would calculate 99th percentile)
--
local function histogram_quantile(phi, vec)
    checks('percent', 'histogram_vector')

    -- sort timeseriess by buckets
    table.sort(vec.timeseriess, bucket_comparator)

    local last_timeseries = vec.timeseriess[#vec.timeseriess]
    local total_count = last_timeseries.observations[1][1]

    local prev_bucket = 0
    local prev_count = 0
    for i, timeseries in pairs(vec.timeseriess) do
        local bucket = timeseries.label_pairs['le']
        if bucket == INF then
            -- for last (infinite) bucket return max bound
            return prev_bucket
        end

        local count = timeseries.observations[1][1]
        if count >= phi * total_count then
            -- linear approximation inside previous bucket
            local coeff = (phi * total_count - prev_count) / (count - prev_count)
            return prev_bucket + (bucket - prev_bucket) * coeff
        end

        prev_bucket = bucket
        prev_count = count
    end

    assert(false, 'unreachable code')
end

local function secs(n) return n * 1000000 end
local function mins(n) return n * secs(60) end
local function hours(n) return n * mins(60) end
local function days(n) return n * hours(24) end
local function weeks(n) return n * days(7) end

------------------------------------- INIT -----------------------------------

local exposed_interface_sandbox = {
    -- monitoring functions
    metric = metric,
    metrics_list = metrics_list,

    -- instant / range vector creator (see Prometheus docs)
    vector = vector,

    -- manipulation functions
    histogram_quantile = histogram_quantile,
    avg_over_time = avg_over_time,
    irate = irate,
    rate = rate,
    increase = increase,
    resets = resets,

    -- time
    secs = secs, seconds = secs,
    mins = mins, minutes = mins,
    hours = hours,
    days = days,
    weeks = weeks
}

-- syntax sugar for acquiring vectors with metric name like this:
--
-- * instant vectors
--  TOO VERBOSE:    vector('http_total', {method = 'GET'})
--  IMRPOVED:       http_total {method = 'GET'}
--
-- * range vectors
--  TOO VERBOSE:    vector('http_total', {method = 'POST'}, 2)
--  IMPROVED:       http_total({method = 'GET'}, 2)
--
setmetatable(exposed_interface_sandbox, {
    __index = function (table, key)
        local metric_name = key
        return function (...)
            return vector(metric_name, ...)
        end
    end,
})

local function execute(query_snippet)
    checks('string')

    local query = assert(loadstring(query_snippet))
    setfenv(query, exposed_interface_sandbox)
    return query()
end

function checkers.positive_number(n)
    return type(n) == 'number' and n > 0
end

--- Starts the Server.
--
--  Server is collecting metrics from clients, deleting observations from
--  timeseriess per retention policy .
--
--  @param options TODO
local function start(options)
    checks {
        retention_tuples = {
            default = 10 * 1000 * 1000,
            type = 'positive_number'
        }
    }

    -- bootstrap tarantool schema
    init()

    expirationd.start(
        'observations_retention',           -- task name
        'observations',                     -- space id
        function (retention_tuples, tuple)  -- expiration callback
            local order = tuple.order_in_ts
            local last_order = next_order(tuple.ts_id) - 1
            return last_order - order >= retention_tuples
        end,
        {args = options.retention_tuples}   -- callback context argument
    )
end

return {
    start = start,
    execute = execute,
    -- client entry
    add_observation = add_observation,
}
