#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

GOLANG_VERSION=1.22.3
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=8920ea521bad8f6b7bc377b4824982e011c19af27df88a815e3586ea895f1b36
GOLANG_DOWNLOAD_SHA256_ARM=6c33e52a5b26e7aa021b94475587fce80043a727a54ceb0eee2f9fc160646434

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
