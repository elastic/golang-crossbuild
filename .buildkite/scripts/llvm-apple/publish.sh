#!/usr/bin/env bash
# Env variables:
# - RELEASE: If set, indicates that this is a production release and images should be pushed to production. For manual releases
# - MAKEFILE: Path to the Makefile to use.
# - STAGING_IMAGE: Docker repository to use for staging images.

set -euo pipefail

source .buildkite/scripts/common.sh

makefile=${1}

add_bin_path

# if RELEASE is not set then set REPOSITORY to STAGING_IMAGE
if [[ -z "${RELEASE:-}" ]]; then
  export REPOSITORY="${STAGING_IMAGE}"
fi

retry 3 make -C ${makefile} push
