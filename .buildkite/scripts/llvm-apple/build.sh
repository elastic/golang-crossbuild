#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}

add_bin_path
with_go "${GOLANG_VERSION}"
with_mage
google_cloud_auth

retry 3 make -C "${makefile}" build GS_BUCKET_PATH=ingest-buildkite-ci
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
