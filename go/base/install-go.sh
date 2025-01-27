#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

GOLANG_VERSION=1.24.0rc2
GOLANG_DOWNLOAD_URL=https://go.dev/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=3835e217efb30c6ace65fcb98cb8f61da3429bfa9e3f6bb4e5e3297ccfc7d1a4
GOLANG_DOWNLOAD_SHA256_ARM=dc8009c89676b2af4410f96ddd815dd0e68047cf97c96a708bf68bf403ff3ef9

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

rm -rf /usr/local/go && tar -C /usr/local -xzf "${GO_TAR_FILE}"
rm "${GO_TAR_FILE}"
