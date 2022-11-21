local fio = require('fio')
local t = require('luatest')
local g = t.group()

local helpers = require('test.helper')

g.before_all(function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
    g.cluster = helpers.init_cluster()
end)

g.after_all(function()
    g.cluster:stop()
    fio.rmtree(g.cluster.datadir)
end)

g.after_each(function()
    local main_server = g.cluster:server("main")
    main_server:exec(function()
        local membership = package.loaded['membership']
        membership.myself = function()
            return {
                status = 'alive',
                payload = {
                    state='RolesConfigured',
                    state_prev='ConfiguringRoles',
                }
            }
        end
    end)
end)

g.test_cartridge_health_handler = function()
    helpers.skip_cartridge_version_less('2.0.2')
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server('main')
    local resp = main_server:http_request('get', '/health', {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_health_fail_handler = function()
    helpers.skip_cartridge_version_less('2.0.2')
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server('main')
    main_server.net_box:eval([[
        _G.old_info = box.info
        box.info = {
            status = 'orphan',
        }
    ]])
    local resp = main_server:http_request('get', '/health', {raise = false})
    t.assert_equals(resp.status, 500)
    main_server.net_box:eval([[
        box.info = _G.old_info
    ]])
end

g.test_cartridge_health_handler_member_alive_state_configured_to_configuring = function()
    helpers.skip_cartridge_version_less("2.0.2")
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server("main")

    main_server:exec(function()
        local membership = package.loaded['membership']
        membership.myself = function()
            return {
                status = 'alive',
                payload = {
                    state='ConfiguringRoles',
                    state_prev='RolesConfigured',
                }
            }
        end
    end)

    local resp = main_server:http_request("get", "/health", {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_health_handler_member_suspect_state_configured_to_configuring = function()
    helpers.skip_cartridge_version_less("2.0.2")
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server("main")

    main_server:exec(function()
        local membership = package.loaded['membership']
        membership.myself = function()
            return {
                status = 'suspect',
                payload = {
                    state='ConfiguringRoles',
                    state_prev='RolesConfigured',
                }
            }
        end
    end)

    local resp = main_server:http_request("get", "/health", {raise = false})
    t.assert_equals(resp.status, 200)
end

g.test_cartridge_health_handler_member_alive_state_boxconfigured_to_configuring = function()
    helpers.skip_cartridge_version_less("2.0.2")
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server("main")

    main_server:exec(function()
        local membership = package.loaded['membership']
        membership.myself = function()
            return {
                status = 'alive',
                payload = {
                    state='ConfiguringRoles',
                    state_prev='BoxConfigured',
                }
            }
        end
    end)

    local resp = main_server:http_request("get", "/health", {raise = false})
    t.assert_equals(resp.status, 500)
end

g.test_cartridge_health_handler_member_suspect_state_boxconfigured_to_configuring = function()
    helpers.skip_cartridge_version_less("2.0.2")
    helpers.upload_default_metrics_config(g.cluster)
    local main_server = g.cluster:server("main")

    main_server:exec(function()
        local membership = package.loaded['membership']
        membership.myself = function()
            return {
                status = 'suspect',
                payload = {
                    state='ConfiguringRoles',
                    state_prev='BoxConfigured',
                }
            }
        end
    end)

    local resp = main_server:http_request("get", "/health", {raise = false})
    t.assert_equals(resp.status, 500)
end
