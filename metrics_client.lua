-- vim: ts=4:sw=4:sts=4:expandtab

require('details.validation')

local net_box = require('net.box')
local fiber = require('fiber')
local log = require('log')
local json = require('json')

local prometheus = require('details.prometheus')

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
        local all_observations = client.registry:collect()
        for _, obs in pairs(all_observations) do
            client.conn:call('add_observation', {obs})
        end
        fiber.sleep(upload_timeout)
    end
end

------------------------------ CLIENT METHODS --------------------------------

local function counter(self, name, help)
    checks('metrics_client', 'string', '?string')

    local obj = prometheus.Counter.new(name, help)
    self.registry:register(obj)
    return obj
end

local function gauge(self, name, help)
    checks('metrics_client', 'string', '?string')

    local obj = prometheus.Gauge.new(name, help)
    self.registry:register(obj)
    return obj
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

local function histogram(self, name, help, buckets)
    checks('metrics_client', 'string', '?string', '?buckets')

    local obj = prometheus.Histogram.new(name, help, buckets)
    self.registry:register(obj)
    return obj
end

local function clear(self)
    checks('metrics_client')

    self.registry.collectors = {}
    self.registry.callbacks = {}
end

-------------------------- PUBLIC INTERFACE ----------------------------------

function checkers.positive_number(n)
    return type(n) == 'number' and n > 0
end

function checkers.port(n)
    return type(n) == 'number' and 0 <= n and n <= 65535
end

--  Creates new client which provides methods for creating collectors.
--
--  @param options Table containing configuration.
--  @param options.host Server host. Default is 'localhost'.
--  @param options.port Server port. Default is 3301.
--  @param options.upload_timeout Upload metrics to the Server. Default is 1 (second).
--
--  @returns Client object
--
local function new(options)
    checks {
        host            = {default = 'localhost'},
        port            = {default = 3301,  type = 'port'},
        upload_timeout  = {default = 1,     type = 'positive_number'},
    }

    -- All collectors will be stored in this registry
    local registry = prometheus.Registry.new()
    assert(registry ~= nil)

    -- Connect to the Server. net_box will try to reconnect every
    -- `upload_timeout` seconds, since we won't be sending data more
    -- frequently anyway.
    local uri = string.format("%s:%d", options.host, options.port)
    local conn = net_box.connect(uri, {
        reconnect_after = options.upload_timeout
    })

    local client = setmetatable({
        registry = registry,
        conn = conn,
    }, {
        __type = 'metrics_client',  -- for validation
        __index = {
            counter = counter,
            gauge = gauge,
            histogram = histogram,
            clear = clear,
        },
    })

    -- Start uploader fiber and return new client
    fiber.create(upload_metrics_worker, client, options.upload_timeout)
    return client
end

return {new = new}
