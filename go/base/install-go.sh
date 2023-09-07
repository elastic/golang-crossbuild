#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

GOLANG_VERSION=1.20.8
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=cc97c28d9c252fbf28f91950d830201aa403836cbed702a05932e63f7f0c7bc4
GOLANG_DOWNLOAD_SHA256_ARM=15ab379c6a2b0d086fe3e74be4599420e66549edf7426a300ee0f3809500f89e

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
