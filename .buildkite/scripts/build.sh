#!/usr/bin/env bash

set -euo pipefail

source .buildkite/scripts/common.sh

MAKEFILE=${1}

check_is_arm

add_bin_path
with_go "${GOLANG_VERSION}"
with_mage

make -C go -f "${MAKEFILE}" build"${is_arm}" GS_BUCKET_PATH=golang-crossbuild-ci-internal

echo "--- List Docker images staging"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${STAGING_IMAGE}/golang-crossbuild"

echo "--- List Docker images production"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" --filter=reference="${DOCKER_REGISTRY}/beats-dev/golang-crossbuild"


