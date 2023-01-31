local metrics

local helpers = require('test.helper')

local t = require('luatest')
local g = t.group()

g.before_all(function()
    t.skip_if(type(helpers) ~= 'table', 'Skip cartridge test')
end)

g.after_each(function()
    metrics.clear()
end)

g.after_all(function()
    package.loaded['cartridge.argparse'] = nil
end)

local function mock_argparse(params)
    package.loaded['cartridge.argparse'] = {
        parse = function()
            return params
        end
    }
    package.loaded['cartridge.roles.metrics'] = nil
    metrics = require('cartridge.roles.metrics')
end

local label_tests = {
    test_init_alias_lebel_present_with_alias_var = {alias = 'alias'},
    test_init_alias_lebel_present_with_instance_var = {instance_name = 'alias'},
    test_init_alias_lebel_is_present_no_alias_var = {},
}

for test_name, params in pairs(label_tests) do
    g[test_name] = function()
        mock_argparse(params)

        metrics.init()

        metrics.counter('test-counter'):inc(1)
        local alias_label = metrics.collect()[1].label_pairs.alias
        t.assert_equals(alias_label, params.alias or params.instance_name)
    end
end
