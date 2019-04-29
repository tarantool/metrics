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
        ['metrics']                              = 'metrics/init.lua',
        ['metrics.server']                       = 'metrics/server/init.lua',
        ['metrics.details']                      = 'metrics/details/init.lua',
        ['metrics.plugins.graphite']             = 'metrics/plugins/graphite/init.lua',
    }
}

-- vim: syntax=lua
