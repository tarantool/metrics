require('strict').on()

local t = require('luatest')
local g = t.group()

local utils = require('test.utils')

g.before_all(utils.create_server)

g.after_all(utils.drop_server)

g.before_each(function(cg)
    cg.server:exec(function()
        local s_vinyl = box.schema.space.create(
            'test_space',
            {if_not_exists = true, engine = 'vinyl'})
        s_vinyl:create_index('pk', {if_not_exists = true})
        require('metrics').enable_default_metrics()
    end)
end)

g.test_vinyl_metrics_present = function(cg)
    cg.server:exec(function()
        local metrics = require('metrics')
        local fun = require('fun')
        local utils = require('test.utils') -- luacheck: ignore 431

        local metrics_cnt = fun.iter(metrics.collect{invoke_callbacks = true}):filter(function(x)
            return x.metric_name:find('tnt_vinyl')
        end):length()
        if utils.is_version_less(_TARANTOOL, '2.8.3')
        and utils.is_version_greater(_TARANTOOL, '2.0.0') then
            t.assert_equals(metrics_cnt, 19)
        else
            t.assert_equals(metrics_cnt, 20)
        end
    end)
end
