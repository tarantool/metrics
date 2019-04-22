-- vim: ts=4:sw=4:sts=4:expandtab

require('checks')

local net_box = require('net.box')
local fiber = require('fiber')

local details = require('metrics.details')

local function collectors()
    return global_metrics_registry.collectors
end

local function register_callback(...)
    return global_metrics_registry:register_callback(...)
end

local function invoke_callbacks()
    return global_metrics_registry:invoke_callbacks()
end

local function collect()
    return global_metrics_registry:collect()
end

--- Fiber which periodically sends observations from all local collectors
--  to the Server.
--
--  Starts on client creation.
--
--  @param client Client object.
--  @param upload_timeout The upload happens every `upload_timeout` seconds.
--
local function upload_metrics_worker(client, upload_timeout)
    while true do
        client.conn:wait_connected()

        invoke_callbacks()
        for _, c in pairs(collectors()) do
            for _, obs in ipairs(c:collect()) do
                client.conn:call('add_observation', {obs})
            end
        end

        fiber.sleep(upload_timeout)
    end
end

function checkers.positive_number(n)
    return type(n) == 'number' and n > 0
end

function checkers.port(n)
    return type(n) == 'number' and 0 <= n and n <= 65535
end

--  Creates new connection to remote server.
--
--  @param options Table containing configuration.
--  @param options.host Server host. Default is 'localhost'.
--  @param options.port Server port. Default is 3301.
--  @param options.upload_timeout Upload metrics to the Server. Default is 1 (second).
--
--  @returns Client object
--
local function connect(options)
    checks {
        host            = '?string',
        port            = '?port',
        upload_timeout  = '?positive_number',
    }
    options = options or {}
    options.host = options.host or 'localhost'
    options.port = options.port or 3301
    options.upload_timeout = options.upload_timeout or 1

    -- Connect to the Server. net_box will try to reconnect every
    -- `upload_timeout` seconds, since we won't be sending data more
    -- frequently anyway.
    local uri = string.format("%s:%d", options.host, options.port)
    local conn = net_box.connect(uri, {
        reconnect_after = options.upload_timeout
    })

    local client = {
        conn = conn
    }

    -- Start uploader fiber and return new client
    fiber.create(upload_metrics_worker, client, options.upload_timeout)
    return client
end

local function counter(name, help)
    checks('string', '?string')

    return details.Counter.new(name, help)
end

local function gauge(name, help)
    checks('string', '?string')

    return details.Gauge.new(name, help)
end

function checkers.buckets(buckets)
    local prev = -math.huge
    for k, v in pairs(buckets) do
        if type(k) ~= 'number' then return false end
        if type(v) ~= 'number' then return false end
        if v <= 0 then return false end
        if prev > v then return false end
        prev = v
    end
    return true
end

local function histogram(name, help, buckets)
    checks('string', '?string', '?buckets')

    return details.Histogram.new(name, help, buckets)
end

local function clear()
    global_metrics_registry.collectors = {}
    global_metrics_registry.callbacks = {}
end

return {
    connect = connect,

    counter = counter,
    gauge = gauge,
    histogram = histogram,

    INF = details.INF,
    NAN = details.NAN,

    clear = clear,
    collectors = collectors,
    register_callback = register_callback,
    invoke_callbacks = invoke_callbacks,
    enable_default_metrics = function()
        return require('metrics.default_metrics.tarantool').enable()
    end,
    collect = collect,
}
