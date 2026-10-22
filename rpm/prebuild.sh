#!/usr/bin/env bash

set -e -o pipefail

curl -LsSf https://www.tarantool.io/release/3/installer.sh | sudo bash
