#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}
patterns=${2}

if ! are_files_changed "$patterns" ; then
    exit 0
fi

add_bin_path
retry 3 make -C ${makefile} push
