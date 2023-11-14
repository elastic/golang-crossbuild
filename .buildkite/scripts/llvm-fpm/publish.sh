#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}
patterns=${2}

#if [[ $(git_diff "$patterns") == false ]]; then
#  exit 0;
#fi

are_files_changed "$patterns"
add_bin_path
retry 3 make -C ${makefile} push
