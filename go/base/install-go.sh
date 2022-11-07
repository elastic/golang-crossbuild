#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

## These variables are automatically bumped.
## If you change their name please change .ci/bump-go-release-version.sh
GOLANG_VERSION=1.19.3
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=74b9640724fd4e6bb0ed2a1bc44ae813a03f1e72a4c76253e2d5c015494430ba
GOLANG_DOWNLOAD_SHA256_ARM=99de2fe112a52ab748fb175edea64b313a0c8d51d6157dba683a6be163fd5eab

GO_TAR_FILE=/tmp/golang.tar.gz

if [ "$(uname -m)" == "x86_64" ]; then
    curl -fsSL "$GOLANG_DOWNLOAD_URL" -o "${GO_TAR_FILE}"
    echo "$GOLANG_DOWNLOAD_SHA256_AMD  ${GO_TAR_FILE}" | sha256sum -c -
fi

GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-arm64.tar.gz

if [ "$(uname -m)" != "x86_64" ]; then
    curl -fsSL "$GOLANG_DOWNLOAD_URL" -o "${GO_TAR_FILE}"
    echo "$GOLANG_DOWNLOAD_SHA256_ARM  ${GO_TAR_FILE}" | sha256sum -c -
fi

tar -C /usr/local -xzf "${GO_TAR_FILE}"
rm "${GO_TAR_FILE}"
