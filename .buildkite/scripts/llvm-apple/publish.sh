#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}

add_bin_path
retry 3 make -C ${makefile} push
