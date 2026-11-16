#!/usr/bin/env bash
# Checks that `docker manifest inspect` reports a published image as found and
# an unpublished image with an error that npcap_image_exists in
# bump-npcap-backports.sh classifies as "missing". Needs a docker login to
# docker.elastic.co.
set -uo pipefail

REPO="docker.elastic.co/observability-ci/golang-crossbuild"
SUFFIX="debian9"
GO_VERSION=$(tr -d '[:space:]' < .go-version)
NPCAP=$(sed -n 's/^NPCAP_VERSION := //p' Makefile.common)

# Same patterns as npcap_image_exists.
is_missing() {
  case "$1" in
    *"no such manifest"*|*"manifest unknown"*|*"not found"*) return 0 ;;
    *) return 1 ;;
  esac
}

status=0

existing="${REPO}:${GO_VERSION}-npcap-${NPCAP}-${SUFFIX}"
echo "--- Published image: ${existing}"
if output=$(docker manifest inspect "$existing" 2>&1); then
  echo "OK: found"
else
  echo "output: ${output}"
  echo "FAIL: expected the image to exist (try another tag if it is not published yet)"
  status=1
fi

missing="${REPO}:0.0.0-npcap-0.0-${SUFFIX}"
echo "--- Unpublished image: ${missing}"
if output=$(docker manifest inspect "$missing" 2>&1); then
  echo "FAIL: expected the image to be missing"
  status=1
else
  echo "output: ${output}"
  if is_missing "$output"; then
    echo "OK: classified as missing"
  else
    echo "FAIL: error not classified as missing"
    status=1
  fi
fi

exit "$status"
