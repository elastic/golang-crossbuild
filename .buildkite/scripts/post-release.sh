#!/bin/bash

set -euo pipefail

source .buildkite/scripts/common.sh

TAG="v{$1}"
TAG_EXISTS=$(tag_Exists ${TAG})

set_git_config() {
    git config user.name "${GITHUB_USERNAME_SECRET}"
    git config user.email "${GITHUB_EMAIL_SECRET}"
}

tag_commit() {
  echo "Tagging commit ${BUILDKITE_COMMIT}"
  git tag -a -m "${BUILDKITE_COMMIT}" "${TAG}"
}

git_push_with_auth() {
  echo "Pushing tag ${TAG}"
  retry 3 git push https://${GITHUB_USERNAME_SECRET}:${GITHUB_TOKEN_SECRET}@github.com/elastic/golang-crossbuild.git ${TAG}
}

if [[ "${TAG_EXISTS}" == true ]]; then
  echo "Tag already exists! Exiting Post-release stage."
  exit 1
fi

set_git_config
tag_commit
git_push_with_auth


