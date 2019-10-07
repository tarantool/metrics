#!/usr/bin/env bash

SCRIPT_DIR=`dirname ${BASH_SOURCE[0]-$0}`
cd $SCRIPT_DIR/tests

. ../beautify_tests.sh

register_test 'default_metrics' <<-EOF
    honcho start -f ./Procfile
    rm -rf master_waldir/*
    rm -rf replica_waldir/*
EOF

register_test 'collectors' <<-EOF
    ./test_collectors.lua
EOF

register_test 'json_plugin' <<-EOF
    ./test_json_plugin.lua
EOF

register_test 'prometheus_plugin' <<-EOF
    ./test_prometheus_plugin.lua
EOF

set -e
run_all_tests
