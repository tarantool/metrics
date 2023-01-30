-- Based on https://github.com/tarantool/crud/blob/73bf5bf9353f9b9ee69c95bb14c610be8f2daeac/crud/common/stash.lua

local stash = {}

--- Available stashes list.
--
-- @tfield string cfg
--  Stash for metrics module configuration.
--
stash.name = {
    cfg = '__metrics_cfg',
    cfg_internal = '__metrics_cfg_internal'
}

--- Setup Tarantool Cartridge reload.
--
-- @function setup_cartridge_reload
--
-- @return Returns
--
function stash.setup_cartridge_reload()
    local hotreload = require('cartridge.hotreload')
    for _, name in pairs(stash.name) do
        hotreload.whitelist_globals({ name })
    end
end

--- Get a stash instance, initialize if needed.
--
--  Stashes are persistent to package reload.
--  To use them with Cartridge roles reload,
--  call `stash.setup_cartridge_reload` in role.
--
-- @function get
--
-- @string name
--  Stash identifier. Use one from `stash.name` table.
--
-- @treturn table A stash instance.
--
function stash.get(name)
    local instance = rawget(_G, name) or {}
    rawset(_G, name, instance)

    return instance
end

return stash
