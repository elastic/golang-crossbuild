#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}
patterns=${2}
docker_filter_ref=${3}

if ! are_files_changed "$patterns" ; then
    exit 0
fi

retry 3 make -C "${makefile}" build GS_BUCKET_PATH=ingest-buildkite-ci
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${docker_filter_ref}"
