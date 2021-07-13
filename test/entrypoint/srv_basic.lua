#!/usr/bin/env tarantool

require('strict').on()

local log = require('log')
local errors = require('errors')
local cartridge = require('cartridge')
errors.set_deprecation_handler(function(err)
    log.error('%s', err)
    os.exit(1)
end)

local ok, err = errors.pcall('CartridgeCfgError', cartridge.cfg, {
    roles = {
        'cartridge.roles.metrics',
    },
    roles_reload_allowed = os.getenv('TARANTOOL_ROLES_RELOAD_ALLOWED') == 'true' or nil,
})
if not ok then
    log.error('%s', err)
    os.exit(1)
end

local metrics = require('cartridge.roles.metrics')
metrics.set_export({
    {
        path = '/health',
        format = 'health'
    },
    {
        path = '/metrics',
        format = 'json'
    },
})
