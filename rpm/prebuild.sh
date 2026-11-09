#!/usr/bin/env bash

set -e -o pipefail

if [ "${OS:-}" = "almalinux" ]; then
    tarantool_series=3
else
    tarantool_series=1.10
fi

curl -LsSf "https://www.tarantool.io/release/${tarantool_series}/installer.sh" | sudo bash
