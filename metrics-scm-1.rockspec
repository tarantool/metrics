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
    type = 'cmake',
    variables = {
        TARANTOOL_INSTALL_LUADIR = '$(LUADIR)',
    },
}

-- vim: syntax=lua
