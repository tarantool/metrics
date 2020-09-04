package = 'metrics'
version = 'scm-1'

source  = {
    url    = 'git://github.com/tarantool/metrics.git',
    branch = 'master'
}

description = {
    summary     = "A centralized system for collecting and manipulating metrics from multiple clients",
    homepage    = '',
    license     = 'BSD',
    maintainer  = "Albert Sverdlov <sverdlov@tarantool.org>";
}

dependencies = {
    'lua >= 5.1',
    'checks >= 2.0.0',
}

build = {
    type = 'builtin',

    modules = {
        ['metrics']                                      = 'metrics/init.lua',
        ['metrics.registry']                             = 'metrics/registry.lua',
        ['metrics.quantile']                             = 'metrics/quantile.lua',
        ['metrics.http_middleware']                      = 'metrics/http_middleware.lua',
        ['metrics.collectors.shared']                    = 'metrics/collectors/shared.lua',
        ['metrics.collectors.average']                   = 'metrics/collectors/average.lua',
        ['metrics.collectors.summary']                   = 'metrics/collectors/summary.lua',
        ['metrics.collectors.counter']                   = 'metrics/collectors/counter.lua',
        ['metrics.collectors.gauge']                     = 'metrics/collectors/gauge.lua',
        ['metrics.collectors.histogram']                 = 'metrics/collectors/histogram.lua',
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
        ['metrics.psutils.cpu']                          = 'metrics/psutils/cpu.lua',
        ['metrics.psutils.psutils_linux']                = 'metrics/psutils/psutils_linux.lua',
        ['metrics.utils']                                = 'metrics/utils.lua',
        ['cartridge.roles.metrics']                      = 'cartridge/roles/metrics.lua',
        ['libquantile']                                  = 'metrics/quantile.c',
    }
}

-- vim: syntax=lua
