package = 'metrics'
version = 'scm-1'

source  = {
    url    = 'git+https://github.com/tarantool/metrics.git',
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
        ['metrics']                         = 'metrics/init.lua',
        ['metrics.api']                     = 'metrics/api.lua',
        ['metrics.registry']                = 'metrics/registry.lua',
        ['metrics.quantile']                = 'metrics/quantile.lua',
        ['metrics.http_middleware']         = 'metrics/http_middleware.lua',
        ['metrics.collectors.shared']       = 'metrics/collectors/shared.lua',
        ['metrics.collectors.summary']      = 'metrics/collectors/summary.lua',
        ['metrics.collectors.counter']      = 'metrics/collectors/counter.lua',
        ['metrics.collectors.gauge']        = 'metrics/collectors/gauge.lua',
        ['metrics.collectors.histogram']    = 'metrics/collectors/histogram.lua',
        ['metrics.const']                   = 'metrics/const.lua',
        ['metrics.plugins.graphite']        = 'metrics/plugins/graphite.lua',
        ['metrics.plugins.prometheus']      = 'metrics/plugins/prometheus.lua',
        ['metrics.plugins.json']            = 'metrics/plugins/json.lua',
        ['metrics.tarantool']               = 'metrics/tarantool.lua',
        ['metrics.tarantool.fibers']        = 'metrics/tarantool/fibers.lua',
        ['metrics.tarantool.info']          = 'metrics/tarantool/info.lua',
        ['metrics.tarantool.memory']        = 'metrics/tarantool/memory.lua',
        ['metrics.tarantool.memtx']         = 'metrics/tarantool/memtx.lua',
        ['metrics.tarantool.network']       = 'metrics/tarantool/network.lua',
        ['metrics.tarantool.operations']    = 'metrics/tarantool/operations.lua',
        ['metrics.tarantool.replicas']      = 'metrics/tarantool/replicas.lua',
        ['metrics.tarantool.runtime']       = 'metrics/tarantool/runtime.lua',
        ['metrics.tarantool.slab']          = 'metrics/tarantool/slab.lua',
        ['metrics.tarantool.spaces']        = 'metrics/tarantool/spaces.lua',
        ['metrics.tarantool.system']        = 'metrics/tarantool/system.lua',
        ['metrics.tarantool.cpu']           = 'metrics/tarantool/cpu.lua',
        ['metrics.tarantool.event_loop']    = 'metrics/tarantool/event_loop.lua',
        ['metrics.cartridge.issues']        = 'metrics/cartridge/issues.lua',
        ['metrics.cartridge.failover']      = 'metrics/cartridge/failover.lua',
        ['metrics.tarantool.clock']         = 'metrics/tarantool/clock.lua',
        ['metrics.psutils.cpu']             = 'metrics/psutils/cpu.lua',
        ['metrics.psutils.psutils_linux']   = 'metrics/psutils/psutils_linux.lua',
        ['metrics.tarantool.luajit']        = 'metrics/tarantool/luajit.lua',
        ['metrics.tarantool.vinyl']         = 'metrics/tarantool/vinyl.lua',
        ['metrics.utils']                   = 'metrics/utils.lua',
        ['metrics.cfg']                     = 'metrics/cfg.lua',
        ['metrics.stash']                   = 'metrics/stash.lua',
        ['metrics.version']                 = 'metrics/version.lua',
        ['cartridge.roles.metrics']         = 'cartridge/roles/metrics.lua',
        ['cartridge.health']                = 'cartridge/health.lua',

        ['override.metrics']                         = 'override/metrics/init.lua',
        ['override.metrics.api']                     = 'override/metrics/api.lua',
        ['override.metrics.registry']                = 'override/metrics/registry.lua',
        ['override.metrics.quantile']                = 'override/metrics/quantile.lua',
        ['override.metrics.http_middleware']         = 'override/metrics/http_middleware.lua',
        ['override.metrics.collectors.shared']       = 'override/metrics/collectors/shared.lua',
        ['override.metrics.collectors.summary']      = 'override/metrics/collectors/summary.lua',
        ['override.metrics.collectors.counter']      = 'override/metrics/collectors/counter.lua',
        ['override.metrics.collectors.gauge']        = 'override/metrics/collectors/gauge.lua',
        ['override.metrics.collectors.histogram']    = 'override/metrics/collectors/histogram.lua',
        ['override.metrics.const']                   = 'override/metrics/const.lua',
        ['override.metrics.plugins.graphite']        = 'override/metrics/plugins/graphite.lua',
        ['override.metrics.plugins.prometheus']      = 'override/metrics/plugins/prometheus.lua',
        ['override.metrics.plugins.json']            = 'override/metrics/plugins/json.lua',
        ['override.metrics.tarantool']               = 'override/metrics/tarantool.lua',
        ['override.metrics.tarantool.fibers']        = 'override/metrics/tarantool/fibers.lua',
        ['override.metrics.tarantool.info']          = 'override/metrics/tarantool/info.lua',
        ['override.metrics.tarantool.memory']        = 'override/metrics/tarantool/memory.lua',
        ['override.metrics.tarantool.memtx']         = 'override/metrics/tarantool/memtx.lua',
        ['override.metrics.tarantool.network']       = 'override/metrics/tarantool/network.lua',
        ['override.metrics.tarantool.operations']    = 'override/metrics/tarantool/operations.lua',
        ['override.metrics.tarantool.replicas']      = 'override/metrics/tarantool/replicas.lua',
        ['override.metrics.tarantool.runtime']       = 'override/metrics/tarantool/runtime.lua',
        ['override.metrics.tarantool.slab']          = 'override/metrics/tarantool/slab.lua',
        ['override.metrics.tarantool.spaces']        = 'override/metrics/tarantool/spaces.lua',
        ['override.metrics.tarantool.system']        = 'override/metrics/tarantool/system.lua',
        ['override.metrics.tarantool.cpu']           = 'override/metrics/tarantool/cpu.lua',
        ['override.metrics.tarantool.event_loop']    = 'override/metrics/tarantool/event_loop.lua',
        ['override.metrics.cartridge.issues']        = 'override/metrics/cartridge/issues.lua',
        ['override.metrics.cartridge.failover']      = 'override/metrics/cartridge/failover.lua',
        ['override.metrics.tarantool.clock']         = 'override/metrics/tarantool/clock.lua',
        ['override.metrics.psutils.cpu']             = 'override/metrics/psutils/cpu.lua',
        ['override.metrics.psutils.psutils_linux']   = 'override/metrics/psutils/psutils_linux.lua',
        ['override.metrics.tarantool.luajit']        = 'override/metrics/tarantool/luajit.lua',
        ['override.metrics.tarantool.vinyl']         = 'override/metrics/tarantool/vinyl.lua',
        ['override.metrics.utils']                   = 'override/metrics/utils.lua',
        ['override.metrics.cfg']                     = 'override/metrics/cfg.lua',
        ['override.metrics.stash']                   = 'override/metrics/stash.lua',
        ['override.metrics.version']                 = 'override/metrics/version.lua',
        ['override.cartridge.roles.metrics']         = 'override/cartridge/roles/metrics.lua',
        ['override.cartridge.health']                = 'override/cartridge/health.lua',
    }
}

-- vim: syntax=lua
