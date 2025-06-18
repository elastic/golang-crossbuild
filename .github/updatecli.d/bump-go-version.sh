#!/usr/bin/env bash
#
# Given the Microsoft Golang release version this script will bump the version.
#
# This script is executed by the automation we are putting in place
#
# NOTE: 
#   * sha256 is retrieved from https://pkg.go.dev/golang.org/x/website/internal/dl?utm_source=godoc
#   * sha256 is retrieved from https://aka.ms/golang/release/latest/go${MAJOR_MINOR_PATCH_VERSION}.assets.json
#
# Parameters:
#	$1 -> the Microsoft Golang release version to be bumped. Mandatory.
#
set -euo pipefail
MSG="parameter missing."
GO_RELEASE_VERSION=${1:?$MSG}
OS=$(uname -s| tr '[:upper:]' '[:lower:]')
if [ "${OS}" == "darwin" ] ; then
	SED="sed -i .bck"
else
	SED="sed -i"
fi

# Process the GO_RELEASE_VERSION to extract major, minor, patch and security versions
MAJOR_MINOR_PATCH_VERSION=$(echo "$GO_RELEASE_VERSION" | sed -E -e "s#([0-9]+\.[0-9]+\.[0-9]+).*#\1#g")
SECURITY_VERSION=$(echo "$GO_RELEASE_VERSION" | sed -E -e "s#([0-9]+\.[0-9]+\.[0-9]+)(.+)#\2#g")

# Gather golang/go sha256 values
GOLANG_DOWNLOAD_SHA256_ARM=$(curl -s -L https://golang.org/dl/\?mode\=json | jq -r ".[] | select( .version | contains(\"go${GO_RELEASE_VERSION}\")) | .files[] | select (.filename | contains(\"go${GO_RELEASE_VERSION}.linux-arm64.tar.gz\")) | .sha256")
GOLANG_DOWNLOAD_SHA256_AMD=$(curl -s -L https://golang.org/dl/\?mode\=json | jq -r ".[] | select( .version | contains(\"go${GO_RELEASE_VERSION}\")) | .files[] | select (.filename | contains(\"go${GO_RELEASE_VERSION}.linux-amd64.tar.gz\")) | .sha256")

# Gather microsoft/go sha256 values
MSFT_DOWNLOAD_METADATA=$(curl -s -L https://aka.ms/golang/release/latest/go${MAJOR_MINOR_PATCH_VERSION}.assets.json)
MSFT_DOWNLOAD_SHA256_ARM=$(echo $MSFT_DOWNLOAD_METADATA | jq -r ".arches[] | select( .env.GOOS == \"linux\") | select( .env.GOARCH == \"arm64\") | .sha256")
MSFT_DOWNLOAD_SHA256_AMD=$(echo $MSFT_DOWNLOAD_METADATA | jq -r ".arches[] | select( .env.GOOS == \"linux\") | select( .env.GOARCH == \"amd64\") | .sha256")

## As long as https://golang.org/dl/?mode=json supports only 2 major versions
## and there is a new major release, then it's required to parse https://golang.org/dl
## see https://github.com/elastic/golang-crossbuild/pull/389/commits/d0af04f97a2381630ea5e8da5a99f50cf27856a0
if [ -z "$GOLANG_DOWNLOAD_SHA256_ARM" ] ; then
    GOLANG_DOWNLOAD_SHA256_ARM=$(curl -s -L https://golang.org/dl | grep "go${MAJOR_MINOR_PATCH_VERSION}.linux-arm64.tar.gz" -A 5 | grep "<tt>" | sed 's#.*<tt>##g' | sed 's#</t.*##g')
fi

if [ -z "$GOLANG_DOWNLOAD_SHA256_AMD" ] ; then
    GOLANG_DOWNLOAD_SHA256_AMD=$(curl -s -L https://golang.org/dl | grep "go${MAJOR_MINOR_PATCH_VERSION}.linux-amd64.tar.gz" -A 5 | grep "<tt>" | sed 's#.*<tt>##g' | sed 's#</t.*##g')
fi

echo "Update go version ${GO_RELEASE_VERSION}"

find "go" -type f -name Dockerfile.tmpl -print0 |
    while IFS= read -r -d '' line; do
        if echo "$line" | grep -q 'arm' ; then
            ${SED} -E -e "s#(ARG GOLANG_DOWNLOAD_SHA256)=.+#\1=${GOLANG_DOWNLOAD_SHA256_ARM}#g" "$line"
            if [ -n "$MSFT_DOWNLOAD_SHA256_ARM" ]; then
                ${SED} -E -e "s#(ARG MSFT_DOWNLOAD_SHA256)=.+#\1=${MSFT_DOWNLOAD_SHA256_ARM}#g" "$line"
            fi
        else
            ${SED} -E -e "s#(ARG GOLANG_DOWNLOAD_SHA256)=.+#\1=${GOLANG_DOWNLOAD_SHA256_AMD}#g" "$line"
            if [ -n "$MSFT_DOWNLOAD_SHA256_AMD" ]; then
                ${SED} -E -e "s#(ARG MSFT_DOWNLOAD_SHA256)=.+#\1=${MSFT_DOWNLOAD_SHA256_AMD}#g" "$line"
            fi
        fi
        if [ -n "$SECURITY_VERSION" ]; then
            ${SED} -E -e "s#(ARG SECURITY_VERSION)=.*#\1=${SECURITY_VERSION}#g" "$line"
        fi
    done
