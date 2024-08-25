#!/bin/bash
# This script install the Go version correct for each architecture.
set -e

GOLANG_VERSION=1.23.0
GOLANG_DOWNLOAD_URL=https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
GOLANG_DOWNLOAD_SHA256_AMD=905a297f19ead44780548933e0ff1a1b86e8327bb459e92f9c0012569f76f5e3
GOLANG_DOWNLOAD_SHA256_ARM=62788056693009bcf7020eedc778cdd1781941c6145eab7688bd087bce0f8659

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

# Fixes can't start telemetry child process
mkdir -p "$HOME"/.config/go/telemetry
echo "off 2024-08-23" > "$HOME"/.config/go/telemetry/mode
