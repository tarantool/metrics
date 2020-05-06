local metrics = require('metrics')
require('checks')

local prometheus = {}

local function escape(str)
    return str
        :gsub("\\", "\\\\")
        :gsub("\n", "\\n")
        :gsub('"', '\\"')
end

local function serialize_name(name)
    return escape(name)
end

local function serialize_value(value)
    local result
    if type(value) == 'cdata' then
        result = tostring(value)
        -- Luajit cdata type inserts some postfix in the end of the number after tostring() operation
        result = result:gsub("U*LL", "")
    elseif value == metrics.INF then
        result = '+Inf'
    elseif value == -metrics.INF then
        result = '-Inf'
    elseif value ~= value then
        result = 'Nan'
    else
        result = tostring(value)
    end
    return escape(result)
end

local function serialize_label_pairs(label_pairs)
    if next(label_pairs) == nil then
        return ''
    end

    local parts = {}
    for name, value in pairs(label_pairs) do
        local s = string.format('%s="%s"',
            serialize_value(name), serialize_value(value))
        table.insert(parts, s)
    end

    local enumerated_via_comma = table.concat(parts, ',')
    return string.format('{%s}', enumerated_via_comma)
end

local function collect_and_serialize()
    metrics.invoke_callbacks()
    local parts = {}
    for _, c in pairs(metrics.collectors()) do
        table.insert(parts, string.format("# HELP %s %s", c.name, c.help))
        table.insert(parts, string.format("# TYPE %s %s", c.name, c.kind))
        for _, obs in ipairs(c:collect()) do
            local s = string.format('%s%s %s',
                serialize_name(obs.metric_name),
                serialize_label_pairs(obs.label_pairs),
                serialize_value(obs.value)
            )
            table.insert(parts, s)
        end
    end
    return table.concat(parts, '\n') .. '\n'
end

function prometheus.collect_http()
    return {
        status = 200,
        headers = { ['content-type'] = 'text/plain; charset=utf8' },
        body = collect_and_serialize(),
    }
end

return prometheus
