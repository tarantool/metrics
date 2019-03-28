local metrics = require('metrics')
require('checks')

local prometheus = {}

local function escape(str)
    return str
        :gsub("\\", "\\\\")
        :gsub("\n", "\\n")
        :gsub('"', '\\"')
end

local function pickle_name(name)
    return escape(name)
end

local function pickle_label_pairs(label_pairs)
    if next(label_pairs) == nil then
        return ''
    end

    local parts = {}
    for name, value in pairs(label_pairs) do
        local s = tostring(name) .. '=' .. escape(tostring(value))
        table.insert(parts, s)
    end

    local enumerated_via_comma = table.concat(parts, ',')
    return string.format('{%s}', enumerated_via_comma)
end

local function pickle_value(value)
    if value == metrics.INF then
        return '+Inf'
    elseif value == -metrics.INF then
        return '-Inf'
    elseif value ~= value then
        return 'Nan'
    else
        return escape(tostring(value))
    end
end

local function pickle_all()
    local parts = {}
    for _, c in pairs(metrics.collectors()) do
        table.insert(parts, "# HELP " .. c.name .. " " .. c.help)
        table.insert(parts, "# TYPE " .. c.name .. " " .. c.collector)
        for _, obs in ipairs(c:collect()) do
            local s = pickle_name(obs.metric_name)
                   .. pickle_label_pairs(obs.label_pairs)
                   .. ' '
                   .. pickle_value(obs.value)
            table.insert(parts, s)
        end
    end
    return table.concat(parts, '\n')
end

function prometheus.collect_http()
    return {
        status = 200,
        headers = { ['content-type'] = 'text/plain; charset=utf8' },
        body = pickle_all(),
    }
end

return prometheus
