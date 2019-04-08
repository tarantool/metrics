local socket = require('socket')
local fiber = require('fiber')
local metrics = require('metrics')
local checks = require('checks')
local log = require('log')

local graphite = {}

-- Default values
local DEFAULT_PREFIX = 'tarantool'
local DEFAULT_HOST = '127.0.0.1'
local DEFAULT_PORT = 2003
local DEFAULT_SEND_INTERVAL = 2

-- Constants
local LABELS_SEP = ';'

local function format_observation(prefix, obs)
    local metric_path = ('%s.%s'):format(prefix, obs.metric_name)

    if next(obs.label_pairs) then
        local label_pairs_str_parts = {}
        for label, value in pairs(obs.label_pairs) do
            table.insert(label_pairs_str_parts, ('%s=%s'):format(label, value))
        end
        local label_pairs_str = table.concat(label_pairs_str_parts, LABELS_SEP)
        metric_path = metric_path .. LABELS_SEP .. label_pairs_str
    end
    metric_path = metric_path:gsub(' ', '_') -- remove spaces (e.g. in values)

    local ts = tostring(obs.timestamp):sub(1, -4) -- remove ULL suffix
    local graph = ('%s %s %s\n'):format(metric_path, obs.value, ts)

    return graph
end

local function graphite_worker(opts)
    fiber.name('metrics_graphite_worker')

    while true do
        metrics.invoke_callbacks()
        for _, c in pairs(metrics.collectors()) do
            for _, obs in ipairs(c:collect()) do
                local data = format_observation(opts.prefix, obs)
                local numbytes = opts.sock:sendto(opts.host, opts.port, data)
                if numbytes == nil then
                    log.error('Error while sending to host %s port %s data %s',
                              opts.host, opts.port, data)
                end
            end
        end

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

    fiber.create(graphite_worker, {
        prefix = prefix,
        sock = sock,
        host = host,
        port = port,
        send_interval = send_interval,
    })
end

return graphite
