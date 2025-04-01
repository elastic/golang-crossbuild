#!/usr/bin/env bash
#
# Given the Golang microsoft version this script will bump the version.
#
# This script is executed by the automation we are putting in place
#
# Parameters:
#	$1 -> the Golang release version to be bumped. Mandatory.
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

MAJOR_MINOR_PATCH_VERSION=$(echo "$GO_RELEASE_VERSION" | sed -E -e "s#([0-9]+\.[0-9]+\.[0-9]+).*#\1#g")
SECURITY_VERSION=$(echo "$GO_RELEASE_VERSION" | sed -E -e "s#([0-9]+\.[0-9]+\.[0-9]+)(.+)#\2#g")

# Gather microsoft/go sha256 values
MSFT_DOWNLOAD_METADATA=$(curl -s -L https://aka.ms/golang/release/latest/go${MAJOR_MINOR_PATCH_VERSION}.assets.json)
MSFT_DOWNLOAD_SHA256_ARM=$(echo $MSFT_DOWNLOAD_METADATA | jq -r ".arches[] | select( .env.GOOS == \"linux\") | select( .env.GOARCH == \"arm64\") | .sha256")
MSFT_DOWNLOAD_SHA256_AMD=$(echo $MSFT_DOWNLOAD_METADATA | jq -r ".arches[] | select( .env.GOOS == \"linux\") | select( .env.GOARCH == \"amd64\") | .sha256")

echo "Update go version ${GO_RELEASE_VERSION}"

find "go" -type f -name Dockerfile.tmpl -print0 |
    while IFS= read -r -d '' line; do
        ${SED} -E -e "s#(ARG GOLANG_VERSION)=[0-9]+\.[0-9]+(\.[0-9]+)?#\1=${MAJOR_MINOR_PATCH_VERSION}#g" "$line"
        if echo "$line" | grep -q 'arm' ; then
            ${SED} -E -e "s#(ARG MSFT_DOWNLOAD_SHA256)=.+#\1=${MSFT_DOWNLOAD_SHA256_ARM}#g" "$line"
            ${SED} -E -e "s#(ARG SECURITY_VERSION)=.*#\1=${SECURITY_VERSION}#g" "$line"
        else
            ${SED} -E -e "s#(ARG MSFT_DOWNLOAD_SHA256)=.+#\1=${MSFT_DOWNLOAD_SHA256_AMD}#g" "$line"
            ${SED} -E -e "s#(ARG SECURITY_VERSION)=.*#\1=${SECURITY_VERSION}#g" "$line"
        fi
    done
