#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}
patterns=${2}
docker_filter_ref=${3}

#if [[ $(git_diff "$patterns") == false ]]; then
#  echo ""
#  exit 0;
#fi

are_files_changed "$patterns"
add_bin_path
with_go "${GOLANG_VERSION}"
with_mage

retry 3 make -C "${makefile}" build GS_BUCKET_PATH=ingest-buildkite-ci
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${docker_filter_ref}"
