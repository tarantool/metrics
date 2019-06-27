#!/usr/bin/env tarantool

require('strict').on()
local tap = require('tap')
local fiber = require('fiber')
local fio = require('fio')
local log = require('log')

local metrics = require('metrics')
local utils = require('utils')

function get_script_dir()
    local str = debug.getinfo(2, 'S').source:sub(2)
    local path = str:match('(.*/)') or '.'
    return fio.abspath(path)
end

local WORK_DIR = fio.pathjoin(get_script_dir(), 'master_waldir')

-- master
box.cfg{                      -- luacheck: ignore
    listen = '3301',
    read_only = false,
    replication = nil,        -- master is replica for no one
    work_dir = WORK_DIR,
}

box.once("schema", function()
    box.schema.user.create('replicator', {password = 'password'})
    box.schema.user.grant('replicator', 'replication') -- grant replication role
    local s = box.schema.space.create('random_space')
    s:create_index('pk')
    log.info('bootstrapped OK on master')
end)

local function ensure_not_throws(test, desc, f)
    local ok, msg = pcall(f)
    if not ok then
        log.info(msg)
    end
    test:ok(ok, desc .. ' not throws')
end

local test = tap.test("http")
test:plan(1)

fiber.sleep(2)
ensure_not_throws(test, 'collect default metrics', function()
    metrics.enable_default_metrics()
    metrics.invoke_callbacks()
end)

os.exit(test:check() and 0 or 1)
