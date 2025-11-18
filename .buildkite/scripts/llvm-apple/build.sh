#!/usr/bin/env bash
# This script builds the Docker images but does not push them to a registry.
# Env variables:
# - RELEASE: If set, indicates that this is a production release and images should be name to production. For manual releases
# - GOLANG_VERSION: Version of Go to use for the build. Defaults to the value in .buildkite/pipeline.yml.
# - MAKEFILE: Path to the Makefile to use.
# - STAGING_IMAGE: Docker repository to use for staging images.

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}

add_bin_path
with_go "${GOLANG_VERSION}"
with_mage

# if RELEASE is not set then set REPOSITORY to STAGING_IMAGE
if [[ -z "${RELEASE:-}" ]]; then
  export REPOSITORY="${STAGING_IMAGE}"
fi

echo "Checking python installation"
echo $(which python3)

retry 3 make -C "${makefile}" build GS_BUCKET_PATH=golang-crossbuild-ci-internal

echo "--- List Docker images"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
