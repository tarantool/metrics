require('strict').on()

local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

g.before_all(utils.create_server)

g.after_all(utils.drop_server)

g.test_needs_upgrade = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local schema = require('metrics.tarantool.schema')
        local utils = require('test.utils') -- luacheck: ignore 431

        metrics.enable_default_metrics()
        schema.update()
        local default_metrics = metrics.collect()
        local schema_needs_upgrade_metric = utils.find_metric('tnt_schema_needs_upgrade', default_metrics)
        t.assert(schema_needs_upgrade_metric)
        t.assert_type(schema_needs_upgrade_metric[1].value, 'number')
    end)
end
