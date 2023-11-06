#!/bin/bash

set -euo pipefail

WORKSPACE="$(pwd)/bin"
HW_TYPE="$(uname -m)"
PLATFORM_TYPE="$(uname)"
TMP_FOLDER="tmp.${REPO}"
GOOGLE_CREDENTIALS_FILENAME="google-cloud-credentials.json"

add_bin_path() {
    echo "Adding PATH to the environment variables..."
    create_workspace
    export PATH="${PATH}:${WORKSPACE}"
}

with_go() {
    local go_version="${1}"
    echo "Setting up the Go environment..."
    create_workspace
    check_platform_architecture
    retry 5 curl -sL -o ${WORKSPACE}/gvm "https://github.com/andrewkroh/gvm/releases/download/${SETUP_GVM_VERSION}/gvm-${PLATFORM_TYPE}-${arch_type}"
    export PATH="${PATH}:${WORKSPACE}"
    chmod +x ${WORKSPACE}/gvm
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
    create_workspace
    for pkg in "${install_packages[@]}"; do
        go install "${pkg}@latest"
    done
}

create_workspace() {
    if [[ ! -d "${WORKSPACE}" ]]; then
    mkdir -p ${WORKSPACE}
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

google_cloud_auth() {
    local gsUtilLocation=$(mktemp -d -p ${WORKSPACE} -t "${TMP_FOLDER}.XXXXXXXXX")
    local secretFileLocation=${gsUtilLocation}/${GOOGLE_CREDENTIALS_FILENAME}
    echo "${PRIVATE_CI_GCS_CREDENTIALS_SECRET}" > ${secretFileLocation}
    gcloud auth activate-service-account --key-file ${secretFileLocation} 2> /dev/null
    export GOOGLE_APPLICATION_CREDENTIALS=${secretFileLocation}
}

unset_secrets () {
  for var in $(printenv | sed 's;=.*;;' | sort); do
    if [[ "$var" == *_SECRET || "$var" == *_TOKEN ]]; then
      unset "$var"
    fi
  done
}

google_cloud_logout_active_account() {
  local active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
  if [[ -n "$active_account" && -n "${GOOGLE_APPLICATION_CREDENTIALS+x}" ]]; then
    echo "Logging out from GCP for active account"
    gcloud auth revoke $active_account > /dev/null 2>&1
  else
    echo "No active GCP accounts found."
  fi
  if [ -n "${GOOGLE_APPLICATION_CREDENTIALS+x}" ]; then
    unset GOOGLE_APPLICATION_CREDENTIALS
    cleanup
  fi
}

cleanup() {
  echo "Deleting temporary files..."
  rm -rf ${WORKSPACE}/${TMP_FOLDER}.*
  echo "Done."
}

releaseExists() {
  local ghSecret=$1
  local tag=$2
  local url=https://api.github.com/repos/elastic/${REPO}/releases/tags/${tag}
  local status=$(curl -s -o /dev/null -w "%{http_code}" -u ${ghSecret}:x-oauth-basic ${url})

  if [ "${status}" == "200" ]; then
    echo "true"
  else
    echo "false"
  fi
}

check_is_arm() {
  if [[ ${HW_TYPE} == "aarch64" || ${HW_TYPE} == "arm64" ]]; then
    is_arm="-arm"
  else
    is_arm=""
  fi
}
