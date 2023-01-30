#!/usr/bin/env tarantool

local workdir = os.getenv('TARANTOOL_WORKDIR')
local listen = os.getenv('TARANTOOL_LISTEN')
local log = os.getenv('TARANTOOL_LOG')

box.cfg({work_dir = workdir, log = log})
box.schema.user.grant('guest', 'super', nil, nil, {if_not_exists=true})
box.cfg({listen = listen})
