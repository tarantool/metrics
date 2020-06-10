local cartridge = require('cartridge')
local argparse = require('cartridge.argparse')
local metrics = require('metrics')
local checks = require('checks')

local handlers = {
    ['json'] = function(req)
        local json_exporter = require('metrics.plugins.json')
        return req:render({ text = json_exporter.export() })
    end,
    ['prometheus'] = function(...)
        local http_handler = require('metrics.plugins.prometheus').collect_http
        return http_handler(...)
    end,
}

local function init()
    local params, err = argparse.parse()
    assert(params, err)
    metrics.set_global_labels({alias = params.alias})
    metrics.enable_default_metrics()
end

local function check_config(_)
    checks({
        export = 'table',
    })
end

local function delete_route(httpd, name)
    httpd.routes[httpd.iroutes[name]] = nil
    httpd.iroutes[name] = nil
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

local function validate_config(conf_new)
    conf_new = conf_new.metrics
    if conf_new == nil then
        return true
    end
    check_config(conf_new)
    local paths = {}
    for _, v in ipairs(conf_new.export) do
        v.path = remove_side_slashes(v.path)
        assert(type(v.path) == 'string', 'export.path must be string')
        assert(handlers[v.format], 'format must be "json" or "prometheus"')
        assert(paths[v.path] == nil, 'paths must be unique')
        paths[v.path] = true
    end
    return true
end

-- table to store enabled routes
local current_paths = {}

-- removes routes that changed in config and adds new routes
local function apply_config(conf)
    local metrics_conf = conf.metrics
    if metrics_conf == nil then
        if next(current_paths) == nil then
            return true
        end
        metrics_conf = { collect = {}, export = {} }
    end

    local httpd = cartridge.service_get('httpd')
    for _, exporter in ipairs(metrics_conf.export) do
        local path, format = remove_side_slashes(exporter.path), exporter.format
        if current_paths[path] ~= format then
            if current_paths[path] then
                delete_route(httpd, path)
            end
            httpd:route({method = 'GET', name = path, path = path}, handlers[format])
            current_paths[path] = format
        end
    end
    -- deletes paths that was enabled, but aren't in config now
    for path, _ in pairs(current_paths) do
        local is_present = false
        for _, exporter in ipairs(metrics_conf.export) do
            if path == remove_side_slashes(exporter.path) then
                is_present = true
                break
            end
        end
        if not is_present then
            delete_route(httpd, path)
            current_paths[path] = nil
        end
    end
end

return setmetatable({
    role_name = 'metrics',

    init = init,
    validate_config = validate_config,
    apply_config = apply_config
}, { __index = metrics })
