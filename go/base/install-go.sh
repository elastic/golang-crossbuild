#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

GOLANG_VERSION=1.18.1
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256=b3b815f47ababac13810fc6021eb73d65478e0b2db4b09d348eefad9581a2334

GO_TAR_FILE=/tmp/golang.tar.gz

if [ "$(uname -m)" == "x86_64" ]; then
    curl -fsSL "$GOLANG_DOWNLOAD_URL" -o "${GO_TAR_FILE}"
	echo "$GOLANG_DOWNLOAD_SHA256  ${GO_TAR_FILE}" | sha256sum -c -
fi

GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-arm64.tar.gz
GOLANG_DOWNLOAD_SHA256=56a91851c97fb4697077abbca38860f735c32b38993ff79b088dac46e4735633

if [ "$(uname -m)" != "x86_64" ]; then
    curl -fsSL "$GOLANG_DOWNLOAD_URL" -o "${GO_TAR_FILE}"
	echo "$GOLANG_DOWNLOAD_SHA256  ${GO_TAR_FILE}" | sha256sum -c -
fi

tar -C /usr/local -xzf "${GO_TAR_FILE}"
rm "${GO_TAR_FILE}"
