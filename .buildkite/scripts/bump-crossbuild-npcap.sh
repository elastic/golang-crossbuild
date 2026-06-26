#!/usr/bin/env bash
# Opens a PR in elastic/golang-crossbuild bumping NPCAP_VERSION in Makefile.common.
# Reads the target version from Buildkite meta-data set by bump-npcap.sh.
# Exits 0 without doing anything if no new version was detected upstream.
#
# Required environment:
#   VAULT_GITHUB_TOKEN (set by the Buildkite agent; elasticmachine identity)
set -euo pipefail

source "$(dirname "$0")/common.sh"

NPCAP_VERSION=$(buildkite-agent meta-data get "npcap-new-version" --default "")
if [ -z "$NPCAP_VERSION" ]; then
  echo "No new npcap version detected. Skipping."
  exit 0
fi

BRANCH="automation/bump-npcap-${NPCAP_VERSION}"

echo "--- Configuring git"
git config user.name  "elasticmachine"
git config user.email "elasticmachine@elastic.co"
git fetch origin main
git checkout -b "$BRANCH" origin/main

echo "--- Bumping NPCAP_VERSION to ${NPCAP_VERSION} in Makefile.common"
sed -i "s/^NPCAP_VERSION := .*/NPCAP_VERSION := ${NPCAP_VERSION}/" Makefile.common

git add Makefile.common
git commit -m "Bump npcap to version ${NPCAP_VERSION}"

echo "--- Pushing branch ${BRANCH}"
retry 3 git push \
  "https://elasticmachine:${VAULT_GITHUB_TOKEN}@github.com/elastic/golang-crossbuild.git" \
  "${BRANCH}"

echo "--- Opening PR in elastic/golang-crossbuild"
GH_TOKEN="${VAULT_GITHUB_TOKEN}" gh pr create \
  --repo "elastic/golang-crossbuild" \
  --base main \
  --head "${BRANCH}" \
  --title "Bump npcap to version ${NPCAP_VERSION}" \
  --label "automation" \
  --label "dependencies" \
  --body "$(cat <<EOF
Bumps the npcap OEM installer to v${NPCAP_VERSION}.
The artifact has been uploaded to the private GCS store by this automation.

https://github.com/nmap/npcap/releases/tag/v${NPCAP_VERSION}
EOF
)"
