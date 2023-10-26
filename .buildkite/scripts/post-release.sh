#!/bin/bash

set -euo pipefail

source .buildkite/scripts/common.sh

TAG="v{$1}"

echo "Tagging commit ${BUILDKITE_COMMIT}"
git config user.name "elasticsearchmachine"
git config user.email "infra-root+elasticsearchmachine@elastic.co"
git tag -f ${TAG} ${BUILDKITE_COMMIT}
git push -f origin ${TAG}

#git_push_with_auth() {
#    local owner="$1"
#    local repository="$2"
#    local branch="$3"
#
#    retry 3 git push https://${GITHUB_USERNAME_SECRET}:${GITHUB_TOKEN}@github.com/${owner}/${repository}.git "${branch}"
#}
