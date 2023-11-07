#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

MAKEFILE=${1}

check_is_arm
add_bin_path
retry 3 make -C go -f "${MAKEFILE}" push"${is_arm}" TAG_EXTENSION=-buildkite
