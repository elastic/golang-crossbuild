#!/usr/bin/env bash

set -euo pipefail

REPO="golang-crossbuild"
WORKSPACE="$(pwd)"
BIN="${WORKSPACE}/bin"
HW_TYPE="$(uname -m)"
PLATFORM_TYPE="$(uname)"
TMP_FOLDER="tmp.${REPO}"

if [[ -z "${GOLANG_VERSION-""}" ]]; then
    export GOLANG_VERSION=$(cat "${WORKSPACE}/.go-version")
fi

add_bin_path() {
    echo "Adding PATH to the environment variables..."
    create_bin
    export PATH="${PATH}:${BIN}"
}

with_go() {
    local go_version="${1}"
    echo "Setting up the Go environment..."
    create_bin
    check_platform_architecture
    retry 5 curl -sL -o ${BIN}/gvm "https://github.com/andrewkroh/gvm/releases/download/v0.6.0/gvm-${PLATFORM_TYPE}-${arch_type}"
    export PATH="${PATH}:${BIN}"
    chmod +x ${BIN}/gvm
    eval "$(gvm "$go_version")"
    go version
    which go
    export PATH="${PATH}:$(go env GOPATH):$(go env GOPATH)/bin"
}

with_mage() {
    local install_packages=(
            "github.com/magefile/mage"
            "github.com/elastic/go-licenser"
            "golang.org/x/tools/cmd/goimports"
            "github.com/jstemmer/go-junit-report"
            "gotest.tools/gotestsum"
    )
    create_bin
    for pkg in "${install_packages[@]}"; do
        go install "${pkg}@latest"
    done
}

create_bin() {
    if [[ ! -d "${BIN}" ]]; then
    mkdir -p ${BIN}
    fi
}

check_platform_architecture() {
# for downloading the GVM and Terraform packages
  case "${HW_TYPE}" in
   "x86_64")
        arch_type="amd64"
        ;;
    "aarch64")
        arch_type="arm64"
        ;;
    "arm64")
        arch_type="arm64"
        ;;
    *)
    echo "The current platform/OS type is unsupported yet"
    ;;
  esac
}

retry() {
    local retries=$1
    shift
    local count=0
    until "$@"; do
        exit=$?
        wait=$((2 ** count))
        count=$((count + 1))
        if [ $count -lt "$retries" ]; then
            >&2 echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
            sleep $wait
        else
            >&2 echo "Retry $count/$retries exited $exit, no more retries left."
            return $exit
        fi
    done
    return 0
}

unset_secrets () {
  for var in $(printenv | sed 's;=.*;;' | sort); do
    if [[ "$var" == *_SECRET || "$var" == *_TOKEN ]]; then
      unset "$var"
    fi
  done
}

cleanup() {
  echo "Deleting temporary files..."
  rm -rf ${BIN}/${TMP_FOLDER}.*
  echo "Done."
}

tag_Exists() {
  local tag=$1
  local url=https://api.github.com/repos/elastic/${REPO}/releases/tags/${tag}
  local status=$(retry 3 curl -s -o /dev/null -w "%{http_code}" -u ${GITHUB_TOKEN_SECRET}:x-oauth-basic ${url})

  if [ "${status}" == "200" ]; then
    echo true
  else
    echo false
  fi
}

check_is_arm() {
  if [[ ${HW_TYPE} == "aarch64" || ${HW_TYPE} == "arm64" ]]; then
    is_arm="-arm"
  else
    is_arm=""
  fi
}
