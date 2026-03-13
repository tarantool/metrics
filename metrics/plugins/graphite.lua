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

local GRAPHITE_FIBERS = {}

local function create_fiber_table(opts)
    local needLongName = (opts ~= nil)
    opts = opts or {}
    local graphite_fiber = {}

    graphite_fiber.sock = nil

    graphite_fiber.prefix = opts.prefix or DEFAULT_PREFIX
    graphite_fiber.host = opts.host or DEFAULT_HOST
    graphite_fiber.port = opts.port or DEFAULT_PORT
    graphite_fiber.send_interval = opts.send_interval or DEFAULT_SEND_INTERVAL

    graphite_fiber.name = "metrics_graphite_worker"
    if needLongName then
        graphite_fiber.name = graphite_fiber.name .. '_' ..
            graphite_fiber.prefix .. '_' .. graphite_fiber.host .. '_' .. graphite_fiber.port
    end

    return graphite_fiber
end

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

local function graphite_worker(args)
    fiber.name(args.name)

    while true do
        metrics.invoke_callbacks()
        for _, c in pairs(metrics.collectors()) do
            for _, obs in ipairs(c:collect()) do
                local data = graphite.format_observation(args.prefix, obs)
                local numbytes = args.sock:sendto(args.host, args.port, data)
                if numbytes == nil then
                    log.error('Error while sending to host %s port %s data %s',
                              args.host, args.port, data)
                end
            end
        end

        fiber.sleep(args.send_interval)
    end
end

local function start_fiber(input)
    input.sock = socket('AF_INET', 'SOCK_DGRAM', 'udp')
    assert(input.sock ~= nil, 'Socket creation failed')

    input.fiber = fiber.create(graphite_worker, {
        name = input.name,
        prefix = input.prefix,
        sock = input.sock,
        host = input.host,
        port = input.port,
        send_interval = input.send_interval,
    })

    return input
end

local function stop_fiber(input)
    pcall(input.sock.close, input.sock)
    pcall(fiber.kill, input.fiber)
end

function graphite.init(opts)
    checks {
        prefix = '?string',
        host = '?string',
        port = '?number',
        send_interval = '?number'
    }

    local graphite_fiber = create_fiber_table(opts)

    -- require('config'):reload() triggers only validate() and apply()
    -- role's methods without stop().
    -- so, we should kill previous fiber if exist.
    if GRAPHITE_FIBERS[graphite_fiber.name] then
        stop_fiber(GRAPHITE_FIBERS[graphite_fiber.name])
        GRAPHITE_FIBERS[graphite_fiber.name] = nil
        fiber.yield()
    end

    GRAPHITE_FIBERS[graphite_fiber.name] = start_fiber(graphite_fiber)
end

function graphite.stop()
    for _, v in pairs(GRAPHITE_FIBERS) do
        stop_fiber(v)
    end

    GRAPHITE_FIBERS = {}
end

return graphite
