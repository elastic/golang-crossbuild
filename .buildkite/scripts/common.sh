#!/usr/bin/env bash

set -euo pipefail

REPO="golang-crossbuild"
WORKSPACE="$(pwd)"
BIN="${WORKSPACE}/bin"
HW_TYPE="$(uname -m)"
TMP_FOLDER="tmp.${REPO}"
GOOGLE_CREDENTIALS_FILENAME="google-cloud-credentials.json"

if [[ -z "${GOLANG_VERSION-""}" ]]; then
    export GOLANG_VERSION=$(cat "${WORKSPACE}/.go-version")
fi

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
    local gsUtilLocation=$(mktemp -d -p ${BIN} -t "${TMP_FOLDER}.XXXXXXXXX")
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

are_files_changed() {
  changeset=$1

  if git diff --name-only HEAD@{1} HEAD | grep -qE "$changeset"; then
    return 0;
  else
    echo "WARN! No files changed in $changeset"
    return 1;
  fi
}

