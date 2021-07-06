#!/usr/bin/env tarantool

-- require('strict').on()

local log = require('log')
local errors = require('errors')
local cartridge = require('cartridge')
local utils = require('test.utils')
local cartridge_version = require('cartridge.VERSION')

errors.set_deprecation_handler(function(err)
    log.error('%s', err)
    os.exit(1)
end)

local config = {
    roles = {
        'cartridge.roles.metrics',
    },
}

if cartridge_version ~= 'unknown' and utils.is_version_less(cartridge_version, '2.4.0') then
    config['roles_reload_allowed'] = true
end

local ok, err = errors.pcall('CartridgeCfgError', cartridge.cfg, config)
if not ok then
    log.error('%s', err)
    os.exit(1)
end
