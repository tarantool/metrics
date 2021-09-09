local helpers = require('test.helper')

local t = require('luatest')
local g = t.group()

g.before_all = function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
end

g.test_cartridge_issues_before_cartridge_cfg = function()
    require('cartridge.issues')
    local issues = require('metrics.cartridge.issues')
    local ok, error = pcall(issues.update)
    t.assert(ok, error)
end
