#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

## These variables are automatically bumped.
## If you change their name please change .ci/bump-go-release-version.sh
GOLANG_VERSION=1.18.6
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=bb05f179a773fed60c6a454a24141aaa7e71edfd0f2d465ad610a3b8f1dc7fe8
GOLANG_DOWNLOAD_SHA256_ARM=838ffa94158125f16e4aa667ee4f6b499ea57e3e35a7e2517ad357ea06714691

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
