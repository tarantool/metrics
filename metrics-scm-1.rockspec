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
        ['cartridge.roles.metrics']         = 'cartridge/roles/metrics.lua',
        ['cartridge.health']                = 'cartridge/health.lua',
    }
}

-- vim: syntax=lua
