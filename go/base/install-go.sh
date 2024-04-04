#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

GOLANG_VERSION=1.21.9
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=f76194c2dc607e0df4ed2e7b825b5847cb37e34fc70d780e2f6c7e805634a7ea
GOLANG_DOWNLOAD_SHA256_ARM=4d169d9cf3dde1692b81c0fd9484fa28d8bc98f672d06bf9db9c75ada73c5fbc

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
