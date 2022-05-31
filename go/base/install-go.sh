#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

## These variables are automatically bumped.
## If you change their name please change .ci/bump-go-release-version.sh
GOLANG_VERSION=1.18.2
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=e54bec97a1a5d230fc2f9ad0880fcbabb5888f30ed9666eca4a91c5a32e86cbc
GOLANG_DOWNLOAD_SHA256_ARM=fc4ad28d0501eaa9c9d6190de3888c9d44d8b5fb02183ce4ae93713f67b8a35b

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
