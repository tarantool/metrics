local cartridge = require('cartridge')
local argparse = require('cartridge.argparse')
local metrics = require('metrics')
local checks = require('checks')
local log = require('log')

local metrics_vars = require('cartridge.vars').new('metrics_vars')
metrics_vars:new('current_paths', {})
metrics_vars:new('default', {})
metrics_vars:new('config', {})
metrics_vars:new('default_labels', {})
metrics_vars:new('custom_labels', {})

local handlers = {
    ['json'] = function(req)
        local json_exporter = require('metrics.plugins.json')
        return req:render({ text = json_exporter.export() })
    end,
    ['prometheus'] = function(...)
        local http_handler = require('metrics.plugins.prometheus').collect_http
        return http_handler(...)
    end,
    ['health'] = function(...)
        local http_handler = require('cartridge.health').is_healthy
        return http_handler(...)
    end,
}

local function set_labels(custom_labels)
    custom_labels = custom_labels or {}
    local params, err = argparse.parse()
    assert(params, err)
    local this_instance = cartridge.admin_get_servers(box.info.uuid)
    local zone
    if this_instance and this_instance[1] then
        zone = this_instance[1].zone
    end
    local labels = {alias = params.alias or params.instance_name, zone = zone}
    for label, value in pairs(metrics_vars.default_labels) do
        labels[label] = value
    end
    for label, value in pairs(custom_labels) do
        labels[label] = value
    end
    metrics.set_global_labels(labels)
    metrics_vars.custom_labels = custom_labels
end

local function check_config(config)
    checks({
        export = 'table',
        ['global-labels'] = '?table',
        include = '?table',
        exclude = '?table',
    })
    if config.include and config.exclude then
        error("don't use exclude and include sections together", 0)
    end
end

local function delete_route(httpd, name)
    local route = assert(httpd.iroutes[name])
    httpd.iroutes[name] = nil
    table.remove(httpd.routes, route)

    -- Update httpd.iroutes numeration
    for n, r in ipairs(httpd.routes) do
        if r.name then
            httpd.iroutes[r.name] = n
        end
    end
end

-- removes '/' from start and end of the path to avoid paths duplication
local function remove_side_slashes(path)
    if path:startswith('/') then
        path = path:sub(2)
    end
    if path:endswith('/') then
        path = path:sub(1, -2)
    end
    return path
end

local function validate_routes(export)
    local paths = {}
    for _, v in ipairs(export) do
        v.path = remove_side_slashes(v.path)
        assert(type(v.path) == 'string', 'export.path must be string')
        assert(handlers[v.format], 'format must be "json", "prometheus" or "health"')
        assert(paths[v.path] == nil, 'paths must be unique')
        paths[v.path] = true
    end
    return true
end

local function format_paths(export)
    local paths = {}
    for _, exporter in ipairs(export) do
        paths[remove_side_slashes(exporter.path)] = exporter.format
    end
    return paths
end

local function validate_global_labels(custom_labels)
    custom_labels = custom_labels or {}
    for label, _ in pairs(custom_labels) do
        assert(type(label) == 'string', 'label name must me string')
        assert(label ~= 'zone' and label ~= 'alias', 'custom label name is not allowed to be "zone" or "alias"')
    end
    return true
end

local function validate_config(conf_new)
    conf_new = conf_new.metrics
    if conf_new == nil then
        return true
    end
    check_config(conf_new)
    return validate_routes(conf_new.export) and validate_global_labels(conf_new['global-labels'])
end

local function apply_routes(paths)
    local httpd = cartridge.service_get('httpd')
    if httpd == nil then
        return
    end

    for path, format in pairs(metrics_vars.current_paths) do
        if paths[path] ~= format then
            delete_route(httpd, path)
        end
    end

    for path, format in pairs(paths) do
        if metrics_vars.current_paths[path] ~= format then
            httpd:route({
                method = 'GET',
                name = path,
                path = path
            }, handlers[format])
        end
    end

    metrics_vars.current_paths = paths
end

-- removes routes that changed in config and adds new routes
local function apply_config(conf)
    local metrics_conf = conf.metrics or {}
    metrics_conf.export = metrics_conf.export or {}
    set_labels(metrics_conf['global-labels'])
    local paths = format_paths(metrics_conf.export)
    metrics_vars.config = table.copy(paths)
    for path, format in pairs(metrics_vars.default) do
        if paths[path] == nil then
            paths[path] = format
        end
    end
    apply_routes(paths)
    metrics.enable_default_metrics(metrics_conf.include, metrics_conf.exclude)
end

local function set_export(export)
    local ok, err = pcall(validate_routes, export)
    if ok then
        local paths = format_paths(export)
        local current_paths = table.copy(metrics_vars.config)
        for path, format in pairs(paths) do
            if current_paths[path] == nil then
                current_paths[path] = format
            end
        end
        apply_routes(current_paths)
        metrics_vars.default = paths
        log.info('Set default metrics endpoints')
    else
        error(err)
    end
end

local function set_default_labels(default_labels)
    local ok, err = pcall(validate_global_labels, default_labels)
    if ok then
        metrics_vars.default_labels = default_labels
        set_labels(metrics_vars.custom_labels)
    else
        error(err, 0)
    end
end

local function init()
    set_labels(metrics_vars.custom_labels)
    metrics.enable_default_metrics()
    local current_paths = table.copy(metrics_vars.config)
    for path, format in pairs(metrics_vars.default) do
        if current_paths[path] == nil then
            current_paths[path] = format
        end
    end
    apply_routes(current_paths)
end

local function stop()
    local httpd = cartridge.service_get('httpd')
    if httpd ~= nil then
        for path, _ in pairs(metrics_vars.current_paths) do
            delete_route(httpd, path)
        end
    end

    metrics_vars.current_paths = {}
    metrics_vars.config = {}
    metrics_vars.custom_labels = {}
end

return setmetatable({
    role_name = 'metrics',
    permanent = true,
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    set_export = set_export,
    set_default_labels = set_default_labels,
}, { __index = metrics })
