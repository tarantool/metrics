local http_client = require('http.client')
local fiber = require('fiber')
local metrics = require('metrics')
local checks = require('checks')
local log = require('log')

local influxdb = {}

-- Default values
local DEFAULT_DB_NAME = 'tarantool'
local DEFAULT_HOST = '127.0.0.1'
local DEFAULT_PORT = 8086
local DEFAULT_FIELD_NAME = 'value'
local DEFAULT_SEND_INTERVAL = 2

-- Constants
local HTTP_NO_CONTENT = 204

local function send_data(client, url, data)
    local post_data = table.concat(data, '\n')
    local result = client:post(url, post_data)
    if result.status ~= HTTP_NO_CONTENT then
        log.error('Got wrong status %d, while sending to url %s data %s', result.status, url, post_data)
    end
end

local function escape_metric(metric)
    return metric
            :gsub('\\', '\\\\')
            :gsub(' ', '\\ ')
            :gsub(',', '\\,')
end

local function escape_field(tag)
    return escape_metric(tag):gsub('=', '\\=')
end

local function serialize_metric_with_tags(metric, label_pairs)
    metric = escape_metric(metric)
    if next(label_pairs) == nil then
        return metric
    end

    local tags = {}
    for name, value in pairs(label_pairs) do
        local s = escape_field(name) .. '=' .. escape_field(value)
        table.insert(tags, s)
    end

    local combined_tags = table.concat(tags, ',')
    return metric .. ',' .. combined_tags
end

local function serialize_value(value)
    if type(value) == 'string' then
        return '"' .. value:gsub('"', '\\"') .. '"'
    end

    return tostring(value)
end

local function format_point(escaped_field_name, obs)
    local metric_with_tags = serialize_metric_with_tags(obs.metric_name, obs.label_pairs)
    local field_value = ('%s=%s'):format(escaped_field_name, serialize_value(obs.value))
    local ts = tostring(obs.timestamp):gsub('ULL', '000')
    local point_line = ('%s %s %s'):format(metric_with_tags, field_value, ts)

    return point_line
end

local function prepare_metrics_data(escaped_field_name)
    metrics.invoke_callbacks()
    local data = {}
    for _, c in pairs(metrics.collectors()) do
        for _, observation in ipairs(c:collect()) do
            table.insert(data, format_point(escaped_field_name, observation))
        end
    end

    return data
end

local function influxdb_worker(opts)
    fiber.name('metrics_influxdb_worker')

    while true do
        local data = prepare_metrics_data(opts.escaped_field_name)
        send_data(opts.client, opts.write_data_url, data)
        fiber.sleep(opts.send_interval)
    end
end

function influxdb.init(opts)
    checks {
        host = '?string',
        port = '?number',
        db_name = '?string',
        send_interval = '?number',
        field_name = '?string',
        username = '?string',
        password = '?string',
    }

    local base_url = ('http://%s:%d'):format(opts.host or DEFAULT_HOST, opts.port or DEFAULT_PORT)
    local ping_url = base_url .. '/ping'
    local write_data_url = ('%s/write?db=%s'):format(base_url, opts.db_name or DEFAULT_DB_NAME)
    if opts.username ~= nil and opts.username ~= "" then
        write_data_url = write_data_url .. "&u=" .. opts.username
    end
    if opts.password ~= nil and opts.password ~= "" then
        write_data_url = write_data_url .. "&p=" .. opts.password
    end

    local client = http_client.new()
    assert(client ~= nil, 'Http client creation failed')

    local ping_response = client:get(ping_url)
    assert(ping_response.status == HTTP_NO_CONTENT, 'Could not connect to influxDB')

    local field_name = opts.field_name or DEFAULT_FIELD_NAME

    fiber.create(influxdb_worker, {
        client = client,
        write_data_url = write_data_url,
        send_interval = opts.send_interval or DEFAULT_SEND_INTERVAL,
        escaped_field_name = escape_field(field_name),
    })
end

return influxdb