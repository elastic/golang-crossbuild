#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

MAKEFILE=${1}

check_is_arm
retry 3 make -C go -f "${MAKEFILE}" push"${is_arm}"
