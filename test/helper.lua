require('strict').on()

local fio = require('fio')
local utils = require('test.utils')
local t = require('luatest')
local ok, cartridge_helpers = pcall(require, 'cartridge.test-helpers')
if not ok then
    return nil
end
local helpers = table.copy(cartridge_helpers)

helpers.project_root = fio.dirname(debug.sourcedir())

function helpers.entrypoint(name)
    local path = fio.pathjoin(
        helpers.project_root,
        'test', 'entrypoint',
        string.format('%s.lua', name)
    )
    if not fio.path.exists(path) then
        error(path .. ': no such entrypoint', 2)
    end
    return path
end

function helpers.init_cluster()
    local cluster = helpers.Cluster:new({
        datadir = fio.tempdir(),
        server_command = helpers.entrypoint('srv_basic'),
        replicasets = {
            {
                uuid = helpers.uuid('a'),
                roles = {},
                servers = {
                    {instance_uuid = helpers.uuid('a', 1), alias = 'main'},
                    {instance_uuid = helpers.uuid('b', 1), alias = 'replica'},
                },
            },
        },
    })
    cluster:start()
    return cluster
end

function helpers.upload_default_metrics_config(cluster)
    cluster:upload_config({
        metrics = {
            export = {
                {
                    path = '/health',
                    format = 'health'
                },
                {
                    path = '/metrics',
                    format = 'json'
                },
            },
        }
    })
end

function helpers.skip_cartridge_version_less(version)
    local cartridge_version = require('cartridge.VERSION')
    t.skip_if(cartridge_version == 'unknown', 'Cartridge version is unknown, must be v' .. version .. ' or greater')
    t.skip_if(utils.is_version_less(cartridge_version, version),
        'Cartridge version is must be v' .. version .. ' or greater')
end

return helpers
