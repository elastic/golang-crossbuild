#!/usr/bin/env bash
#
# Given the Golang release version this script will bump the version.
#
# This script is executed by the automation we are putting in place
# and it requires the git add/commit commands.
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

echo "Update go version ${GO_RELEASE_VERSION}"
${SED} -E -e "s#(VERSION[[:space:]]+):= .*#\1:= ${GO_RELEASE_VERSION}#g" "go/Makefile.common"
git add "go/Makefile.common"
${SED} -E -e "s#(GO_VERSION[[:space:]]+)= .*#\1= '${GO_RELEASE_VERSION}'#g" Jenkinsfile
git add Jenkinsfile

find "go" -type f -name Dockerfile.tmpl -print0 |
    while IFS= read -r -d '' line; do
        ${SED} -E -e "s#(ARG GOLANG_VERSION)=[0-9]+\.[0-9]+(\.[0-9]+)?#\1=${GO_RELEASE_VERSION}#g" "$line"
        if echo "$line" | grep -q 'arm' ; then
            ${SED} -E -e "s#(ARG GOLANG_DOWNLOAD_SHA256)=.+#\1=${GOLANG_DOWNLOAD_SHA256_ARM}#g" "$line"
        else
            ${SED} -E -e "s#(ARG GOLANG_DOWNLOAD_SHA256)=.+#\1=${GOLANG_DOWNLOAD_SHA256_AMD}#g" "$line"
        fi
        git add "${line}"
    done

if [ -e go/base/install-go.sh ] ; then
    ${SED} -E -e "s#(GOLANG_VERSION)=[0-9]+\.[0-9]+(\.[0-9]+)?#\1=${GO_RELEASE_VERSION}#g" go/base/install-go.sh
    ${SED} -E -e "s#(GOLANG_DOWNLOAD_SHA256_AMD)=.+#\1=${GOLANG_DOWNLOAD_SHA256_AMD}#g" go/base/install-go.sh
    ${SED} -E -e "s#(GOLANG_DOWNLOAD_SHA256_ARM)=.+#\1=${GOLANG_DOWNLOAD_SHA256_ARM}#g" go/base/install-go.sh
    git add go/base/install-go.sh
fi

git diff --staged --quiet || git commit -m "[Automation] Update go release version to ${GO_RELEASE_VERSION}"
git --no-pager log -1

echo "You can now push and create a Pull Request"
