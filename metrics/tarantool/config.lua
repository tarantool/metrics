local utils = require('metrics.utils')

local collectors_list = {}

local function get_config_alerts(config_info)
    -- https://github.com/tarantool/tarantool/blob/319357d5973d15d08b8eda6a230eada08b710802/src/box/lua/config/utils/aboard.lua#L17-L18
    local config_alerts = {
        warn = 0,
        error = 0,
    }

    for _, alert in pairs(config_info.alerts) do
        config_alerts[alert.type] = config_alerts[alert.type] + 1
    end

    return config_alerts
end

local function update()
    if not utils.is_tarantool3() then
        return
    end

    -- Can migrate to box.info().config later
    -- https://github.com/tarantool/tarantool/commit/a1544d3bbc029c6fb2a148e580afe2b20e269b8d
    local config = require('config')
    local config_info = config:info()

    local config_alerts = get_config_alerts(config_info)

    for level, count in pairs(config_alerts) do
        collectors_list.config_alerts = utils.set_gauge(
            'config_alerts',
            'Tarantool 3 configuration alerts',
            count,
            {level = level},
            nil,
            {default = true}
        )
    end
end

return {
    update = update,
    list = collectors_list,
}
