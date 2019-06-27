#!/usr/bin/env tarantool

local fio = require('fio')
local log = require('log')

function get_script_dir()
    local str = debug.getinfo(2, 'S').source:sub(2)
    local path = str:match('(.*/)') or '.'
    return fio.abspath(path)
end

local WORK_DIR = fio.pathjoin(get_script_dir(), 'replica_waldir')

-- replica
box.cfg{                      -- luacheck: ignore
    listen = '3302',
    read_only = true,
    replication = {
        'replicator:password@127.0.0.1:3301',  -- our replication source
    },
    work_dir = WORK_DIR,
}
