require('strict').on()

local t = require("luatest")
local g = t.group('hotreload')

g.test_cpu_reloads = function()
    require('metrics.default_metrics.tarantool.cpu')
    for k in pairs(package.loaded) do
        if k:find('metrics') ~= nil then
            package.loaded[k] = nil
        end
    end
    require('metrics.default_metrics.tarantool.cpu')
end
