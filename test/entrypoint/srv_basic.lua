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
})
if not ok then
    log.error('%s', err)
    os.exit(1)
end
