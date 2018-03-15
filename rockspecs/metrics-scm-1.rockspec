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
    'expirationd'
}

build = {
    type = 'builtin',

    modules = {
        ['metrics.client']                       = 'metrics_client.lua',
        ['metrics.server']                       = 'metrics_server.lua',
        ['metrics.details.prometheus']           = 'details/prometheus.lua',
        ['metrics.details.validation']           = 'details/validation.lua',
    }
}

-- vim: syntax=lua
