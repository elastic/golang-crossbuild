#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

MAKEFILE=${1}

if [[ $(git_diff "$patterns") == false ]]; then
  exit 0;
fi

add_bin_path
retry 3 make -C ${MAKEFILE} push
