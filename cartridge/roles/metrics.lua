local cartridge = require('cartridge')
local argparse = require('cartridge.argparse')
local metrics = require('metrics')
local checks = require('checks')
local log = require('log')

local metrics_vars = require('cartridge.vars').new('metrics_vars')
metrics_vars:new('current_paths', {})
metrics_vars:new('default', {})
metrics_vars:new('config', {})

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

local function set_labels()
    local params, err = argparse.parse()
    assert(params, err)
    local this_instance = cartridge.admin_get_servers(box.info.uuid)
    local zone
    if this_instance and this_instance[1] then
        zone = this_instance[1].zone
    end
    metrics.set_global_labels({alias = params.alias or params.instance_name, zone = zone})
end

local function check_config(_)
    checks({
        export = 'table',
    })
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

local function validate_config(conf_new)
    conf_new = conf_new.metrics
    if conf_new == nil then
        return true
    end
    check_config(conf_new)
    return validate_routes(conf_new.export)
end

local function apply_routes(paths)
    local httpd = cartridge.service_get('httpd')
    if httpd == nil then
        return
    end
    for path, format in pairs(paths) do
        if metrics_vars.current_paths[path] ~= format then
            -- if format was changed then delete old path
            if metrics_vars.current_paths[path] ~= nil then
                delete_route(httpd, path)
            end
            httpd:route({method = 'GET', name = path, path = path}, handlers[format])
        end
    end
    -- deletes paths that was enabled, but aren't in config now
    for path, _ in pairs(metrics_vars.current_paths) do
        if paths[path] == nil and metrics_vars.config[path] == nil then
            delete_route(httpd, path)
        end
    end
    metrics_vars.current_paths = paths
end

-- removes routes that changed in config and adds new routes
local function apply_config(conf)
    local metrics_conf = conf.metrics or {}
    metrics_conf.export = metrics_conf.export or {}
    set_labels()
    local paths = format_paths(metrics_conf.export)
    metrics_vars.config = table.copy(paths)
    for path, format in pairs(metrics_vars.default) do
        if paths[path] == nil then
            paths[path] = format
        end
    end
    apply_routes(paths)
end

local function set_export(export)
    local ok, err = pcall(validate_routes, export)
    if ok then
        local paths = format_paths(export)
        local current_paths = table.copy(metrics_vars.current_paths)
        for path, _ in pairs(metrics_vars.default) do
            current_paths[path] = nil
        end
        for path, format in pairs(paths) do
            if current_paths[path] == nil then
                current_paths[path] = format
            end
        end
        metrics_vars.default = paths
        apply_routes(current_paths)
        log.info('Default metrics paths is set')
    else
        error(err)
    end
end

local function init()
    set_labels()
    metrics.enable_default_metrics()
    metrics.enable_cartridge_metrics()
    local current_paths = table.copy(metrics_vars.current_paths)
    for path, format in pairs(metrics_vars.default) do
        if current_paths[path] == nil then
            current_paths[path] = format
        end
    end
    apply_routes(current_paths)
end

local function stop()
    for path, _ in pairs(metrics_vars.current_paths) do
        local ok, err = pcall(delete_route, path)
        if not ok then
            log.error(err)
        end
    end
    metrics_vars.current_paths = {}
    metrics_vars.config = {}
end

return setmetatable({
    role_name = 'metrics',
    permanent = true,
    init = init,
    stop = stop,
    validate_config = validate_config,
    apply_config = apply_config,
    set_export = set_export,
}, { __index = metrics })
