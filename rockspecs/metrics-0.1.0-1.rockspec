package = 'metrics'
version = '0.1.0-1'

source  = {
    url = 'git://github.com/tarantool/metrics.git',
    tag = '0.1.0'
}

description = {
    summary     = "A centralized system for collecting and manipulating metrics from multiple clients",
    homepage    = '',
    license     = 'BSD',
    maintainer  = "Albert Sverdlov <sverdlov@tarantool.org>";
}

dependencies = {
    'lua >= 5.1',
    'expirationd',
    'checks >= 2.0.0',
}

build = {
    type = 'builtin',

    modules = {
        ['metrics']                                      = 'metrics/init.lua',
        ['metrics.server']                               = 'metrics/server/init.lua',
        ['metrics.details']                              = 'metrics/details/init.lua',
        ['metrics.plugins.graphite']                     = 'metrics/plugins/graphite/init.lua',
        ['metrics.plugins.prometheus']                   = 'metrics/plugins/prometheus/init.lua',
        ['metrics.plugins.json']                         = 'metrics/plugins/json/init.lua',
        ['metrics.default_metrics.tarantool']            = 'metrics/default_metrics/tarantool/init.lua',
        ['metrics.default_metrics.tarantool.fibers']     = 'metrics/default_metrics/tarantool/fibers.lua',
        ['metrics.default_metrics.tarantool.info']       = 'metrics/default_metrics/tarantool/info.lua',
        ['metrics.default_metrics.tarantool.memory']     = 'metrics/default_metrics/tarantool/memory.lua',
        ['metrics.default_metrics.tarantool.network']    = 'metrics/default_metrics/tarantool/network.lua',
        ['metrics.default_metrics.tarantool.operations'] = 'metrics/default_metrics/tarantool/operations.lua',
        ['metrics.default_metrics.tarantool.replicas']   = 'metrics/default_metrics/tarantool/replicas.lua',
        ['metrics.default_metrics.tarantool.runtime']    = 'metrics/default_metrics/tarantool/runtime.lua',
        ['metrics.default_metrics.tarantool.slab']       = 'metrics/default_metrics/tarantool/slab.lua',
        ['metrics.default_metrics.tarantool.spaces']     = 'metrics/default_metrics/tarantool/spaces.lua',
        ['metrics.default_metrics.tarantool.system']     = 'metrics/default_metrics/tarantool/system.lua',
        ['metrics.default_metrics.tarantool.utils']      = 'metrics/default_metrics/tarantool/utils.lua',
    }
}

-- vim: syntax=lua
