#!/usr/bin/env bash
# Opens a PR in elastic/beats bumping the npcap version in:
#   x-pack/packetbeat/npcap/installer/LICENSE
# and adding the required changelog fragment.
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

BEATS_REPO="elastic/beats"
BRANCH="automation/bump-npcap-${NPCAP_VERSION}"
LICENSE_FILE="x-pack/packetbeat/npcap/installer/LICENSE"
CHANGELOG_FILE="changelog/fragments/$(date +%s)-bump-npcap-${NPCAP_VERSION}.yaml"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "--- Cloning ${BEATS_REPO}"
retry 3 git clone --depth=1 --branch main \
  "https://elasticmachine:${VAULT_GITHUB_TOKEN}@github.com/${BEATS_REPO}.git" \
  "$WORK_DIR"

cd "$WORK_DIR"
git config user.name  "elasticmachine"
git config user.email "elasticmachine@elastic.co"
git checkout -b "$BRANCH"

echo "--- Bumping version in ${LICENSE_FILE}"
sed -i "s/^Version: .*/Version: ${NPCAP_VERSION}/" "$LICENSE_FILE"

echo "--- Writing changelog fragment ${CHANGELOG_FILE}"
cat > "$CHANGELOG_FILE" <<EOF
kind: enhancement
summary: Bump bundled Windows Npcap OEM installer to v${NPCAP_VERSION}.
component: packetbeat
EOF

git add "$LICENSE_FILE" "$CHANGELOG_FILE"
git commit -m "[packetbeat] Bump npcap version to ${NPCAP_VERSION}"

echo "--- Pushing branch ${BRANCH}"
retry 3 git push \
  "https://elasticmachine:${VAULT_GITHUB_TOKEN}@github.com/${BEATS_REPO}.git" \
  "${BRANCH}"

echo "--- Opening PR in ${BEATS_REPO}"
GH_TOKEN="${VAULT_GITHUB_TOKEN}" gh pr create \
  --repo "$BEATS_REPO" \
  --base main \
  --head "${BRANCH}" \
  --title "[packetbeat] Bump npcap version to ${NPCAP_VERSION}" \
  --label "automation" \
  --body "$(cat <<EOF
Bump bundled Windows Npcap OEM installer to v${NPCAP_VERSION}.

The OEM artifact has been uploaded to the private GCS store by the automation in elastic/golang-crossbuild.

https://github.com/nmap/npcap/releases/tag/v${NPCAP_VERSION}
EOF
)"
