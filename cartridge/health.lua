local membership = require('membership')
local argparse = require('cartridge.argparse')

local function is_healthy(_)
    local member = membership.myself()
    local parse = argparse.parse()
    local instance = parse.instance_name or parse.alias or 'instance'
    if box.info.status and box.info.status == 'running' and member and
        member.status and member.status == 'alive' and member.payload and
        member.payload.state and member.payload.state == 'RolesConfigured' then
        return {body = instance .. ' is OK', status = 200}
    else
        return {body = instance .. ' is dead', status = 500}
    end
end

return {is_healthy = is_healthy}
