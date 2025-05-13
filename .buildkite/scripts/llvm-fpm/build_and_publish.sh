#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}
docker_filter_ref=${2}

add_bin_path
with_go "${GOLANG_VERSION}"
with_mage

retry 3 make -C "${makefile}" build GS_BUCKET_PATH=ingest-buildkite-ci
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${docker_filter_ref}"
