#!/usr/bin/env tarantool

require('strict').on()

local log = require('log')
local errors = require('errors')
local cartridge = require('cartridge')
local utils = require('test.utils')
local cartridge_version = require('cartridge.VERSION')

errors.set_deprecation_handler(function(err)
    log.error('%s', err)
    os.exit(1)
end)

local ok, err = errors.pcall('CartridgeCfgError', cartridge.cfg, {
    roles = {
        'cartridge.roles.metrics',
    },
    roles_reload_allowed =
        (cartridge_version == 'unknown' or utils.is_version_less(cartridge_version, '2.4.0')) and nil or true,
})
if not ok then
    log.error('%s', err)
    os.exit(1)
end
