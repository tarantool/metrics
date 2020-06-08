require('strict').on()

local fio = require('fio')
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

return helpers
