#!/bin/bash

set -euo pipefail

source .buildkite/scripts/common.sh

MAKEFILE=${1}

check_is_arm
add_bin_path
make -C go -f "${MAKEFILE}" push"${is_arm}"
