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

local roles_reload_allowed

if cartridge_version ~= 'unknown' and utils.is_version_less(cartridge_version, '2.4.0') then
    roles_reload_allowed = true
end

local ok, err = errors.pcall('CartridgeCfgError', cartridge.cfg, {
    roles = {
        'cartridge.roles.metrics',
    },
    roles_reload_allowed = roles_reload_allowed,
})
if not ok then
    log.error('%s', err)
    os.exit(1)
end
