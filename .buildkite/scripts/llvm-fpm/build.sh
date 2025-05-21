#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}
patterns=${2}
docker_filter_ref=${3}

if ! are_files_changed "$patterns" ; then
    exit 0
fi

add_bin_path
with_go "${GOLANG_VERSION}"
with_mage

<<<<<<< HEAD:.buildkite/scripts/llvm-fpm/build.sh
retry 3 make -C "${makefile}" build GS_BUCKET_PATH=ingest-buildkite-ci
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${docker_filter_ref}"
=======
retry 3 make -C "${makefile}" build GS_BUCKET_PATH=golang-crossbuild-ci-internal

echo "--- List Docker images"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
>>>>>>> f041ab3 (bk: use GCP OIDC (#610)):.buildkite/scripts/llvm-apple/build.sh
