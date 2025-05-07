#!/usr/bin/env bash
#
# Given the Golang release version this script will bump the version.
#
# This script is executed by the automation we are putting in place
#
# NOTE: sha256 is retrieved from https://pkg.go.dev/golang.org/x/website/internal/dl?utm_source=godoc
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

MAJOR_MINOR_VERSION=$(echo "$GO_RELEASE_VERSION" | sed -E -e "s#([0-9]+\.[0-9]+).*#\1#g")
GOLANG_DOWNLOAD_SHA256_ARM=$(curl -s -L https://golang.org/dl/\?mode\=json | jq -r ".[] | select( .version | contains(\"go${GO_RELEASE_VERSION}\")) | .files[] | select (.filename | contains(\"go${GO_RELEASE_VERSION}.linux-arm64.tar.gz\")) | .sha256")
GOLANG_DOWNLOAD_SHA256_AMD=$(curl -s -L https://golang.org/dl/\?mode\=json | jq -r ".[] | select( .version | contains(\"go${GO_RELEASE_VERSION}\")) | .files[] | select (.filename | contains(\"go${GO_RELEASE_VERSION}.linux-amd64.tar.gz\")) | .sha256")

# Gather microsoft/go sha256 values
URL=https://aka.ms/golang/release/latest/go${GO_RELEASE_VERSION}.assets.json
if curl -s -L "$URL" > /dev/null ; then
    MSFT_DOWNLOAD_METADATA=$(curl -s -L "$URL")
    MSFT_DOWNLOAD_SHA256_ARM=$(echo $MSFT_DOWNLOAD_METADATA | jq -r ".arches[] | select( .env.GOOS == \"linux\") | select( .env.GOARCH == \"arm64\") | .sha256")
    MSFT_DOWNLOAD_SHA256_AMD=$(echo $MSFT_DOWNLOAD_METADATA | jq -r ".arches[] | select( .env.GOOS == \"linux\") | select( .env.GOARCH == \"amd64\") | .sha256")
    # when a new minor then we use `-1`
    # then nex security versions will be `-2`, `-3`, etc, see bump-microsoft.yml
    SECURITY_VERSION=-1
fi

## As long as https://golang.org/dl/?mode=json supports only 2 major versions
## and there is a new major release, then it's required to parse https://golang.org/dl
## see https://github.com/elastic/golang-crossbuild/pull/389/commits/d0af04f97a2381630ea5e8da5a99f50cf27856a0
if [ -z "$GOLANG_DOWNLOAD_SHA256_ARM" ] ; then
    GOLANG_DOWNLOAD_SHA256_ARM=$(curl -s -L https://golang.org/dl | grep go${GO_RELEASE_VERSION}.linux-arm64.tar.gz -A 5 | grep "<tt>" | sed 's#.*<tt>##g' | sed 's#</t.*##g')
fi

if [ -z "$GOLANG_DOWNLOAD_SHA256_AMD" ] ; then
    GOLANG_DOWNLOAD_SHA256_AMD=$(curl -s -L https://golang.org/dl | grep go${GO_RELEASE_VERSION}.linux-amd64.tar.gz -A 5 | grep "<tt>" | sed 's#.*<tt>##g' | sed 's#</t.*##g')
fi

echo "Update go version ${GO_RELEASE_VERSION}"

find "go" -type f -name Dockerfile.tmpl -print0 |
    while IFS= read -r -d '' line; do
        ${SED} -E -e "s#(ARG GOLANG_VERSION)=[0-9]+\.[0-9]+(\.[0-9]+)?#\1=${GO_RELEASE_VERSION}#g" "$line"
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
