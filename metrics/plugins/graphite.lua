local socket = require('socket')
local fiber = require('fiber')
local metrics = require('metrics')
local string_utils = require('metrics.string_utils')
local checks = require('checks')
local log = require('log')
local fun = require('fun')

local graphite = {}

-- Default values
local DEFAULT_PREFIX = 'tarantool'
local DEFAULT_HOST = '127.0.0.1'
local DEFAULT_PORT = 2003
local DEFAULT_SEND_INTERVAL = 2

-- Constants
local LABELS_SEP = ';'

function graphite.format_observation(prefix, obs)
    local metric_path = #prefix > 0 and ('%s.%s'):format(prefix, obs.metric_name) or obs.metric_name

    if next(obs.label_pairs) then
        local label_pairs_str_parts = {}
        for label, value in pairs(obs.label_pairs) do
            table.insert(label_pairs_str_parts, ('%s=%s'):format(label, value))
        end
        local label_pairs_str = table.concat(label_pairs_str_parts, LABELS_SEP)
        metric_path = metric_path .. LABELS_SEP .. label_pairs_str
    end
    metric_path = metric_path:gsub(' ', '_') -- remove spaces (e.g. in values)
    local string_val = tostring(tonumber(obs.value)) -- removes ULL/LL suffixes

    local ts = tostring(obs.timestamp / 10^6):gsub("U*LL", "") -- Graphite takes time in seconds
    local graph = ('%s %s %s\n'):format(metric_path, string_val, ts)

    return graph
end

graphite.internal = {}
function graphite.internal.collect_and_push_v1(opts)
    metrics.invoke_callbacks()
    for _, c in pairs(metrics.collectors()) do
        for _, obs in ipairs(c:collect()) do
            local data = graphite.format_observation(opts.prefix, obs)
            local numbytes = opts.sock:sendto(opts.host, opts.port, data)
            if numbytes == nil then
                log.error('Error while sending to host %s port %s data %s',
                          opts.host, opts.port, data)
            end
        end
    end
end

function graphite.format_output(output, opts)
    local result = {}
    for _, coll_obs in pairs(output) do
        for group_name, obs_group in pairs(coll_obs.observations) do
            local metric_name = string_utils.build_name(coll_obs.name, group_name)
            for _, obs in pairs(obs_group) do
                local formatted_obs = graphite.format_observation(opts.prefix,
                    {
                        metric_name = metric_name,
                        label_pairs = obs.label_pairs,
                        timestamp = coll_obs.timestamp,
                        value = obs.value
                    })
                table.insert(result, formatted_obs)
            end
        end
    end

    return result
end

function graphite.send_formatted(formatted_output, opts)
    for _, data in ipairs(formatted_output) do
        local numbytes = opts.sock:sendto(opts.host, opts.port, data)
        if numbytes == nil then
            log.error('Error while sending to host %s port %s data %s',
                      opts.host, opts.port, data)
        end
    end
end

function graphite.internal.collect_and_push_v2(opts)
    local output = metrics.collect{invoke_callbacks = true, extended_format = true}
    local formatted_output = graphite.format_output(output, opts)
    graphite.send_formatted(formatted_output, opts)
end

local function graphite_worker(opts)
    fiber.name('metrics_graphite_worker')

    while true do
        graphite.internal.collect_and_push_v2(opts)
        fiber.sleep(opts.send_interval)
    end
end

function graphite.init(opts)
    checks {
        prefix = '?string',
        host = '?string',
        port = '?number',
        send_interval = '?number'
    }

    local sock = socket('AF_INET', 'SOCK_DGRAM', 'udp')
    assert(sock ~= nil, 'Socket creation failed')

    local prefix = opts.prefix or DEFAULT_PREFIX
    local host = opts.host or DEFAULT_HOST
    local port = opts.port or DEFAULT_PORT
    local send_interval = opts.send_interval or DEFAULT_SEND_INTERVAL

    fun.iter(fiber.info()):
        filter(function(_, x) return x.name == 'metrics_graphite_worker' end):
        each(function(x) fiber.kill(x) end)

    fiber.create(graphite_worker, {
        prefix = prefix,
        sock = sock,
        host = host,
        port = port,
        send_interval = send_interval,
    })
end

return graphite
