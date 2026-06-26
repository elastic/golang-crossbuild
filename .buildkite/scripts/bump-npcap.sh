#!/usr/bin/env bash
# Downloads the latest npcap OEM installer from npcap.com and uploads it to the
# private GCS bucket, if a newer version than what is pinned in Makefile.common
# is available. Publishes the new and previous version via Buildkite meta-data
# for use by the downstream bump-crossbuild-npcap.sh and bump-beats-npcap.sh steps.
#
# Required environment:
#   VAULT_ADDR (set by the Buildkite agent)
#   gcloud authenticated via the elastic/oblt-google-auth Buildkite plugin
#
# The NPCAP OEM credentials are read from Vault at runtime; they are NOT passed
# in as environment variables because they cannot be acquired locally without
# Vault access.
set -euo pipefail

source "$(dirname "$0")/common.sh"

GCS_BUCKET="${GCS_BUCKET:-golang-crossbuild-ci-internal}"
MAKEFILE="${WORKSPACE}/Makefile.common"

echo "--- Checking latest npcap release"

# Latest version from the public nmap/npcap GitHub releases API.
LATEST=$(curl -sf https://api.github.com/repos/nmap/npcap/releases/latest \
  | jq -r .tag_name | sed 's/^v//')

# Current version pinned in this repo.
CURRENT=$(grep '^NPCAP_VERSION' "$MAKEFILE" | sed 's/.*:= //')

echo "Current npcap version: ${CURRENT}"
echo "Latest  npcap version: ${LATEST}"

if [ "$LATEST" = "$CURRENT" ]; then
  echo "Already up-to-date at ${CURRENT}. Nothing to do."
  buildkite-agent meta-data set "npcap-new-version" ""
  exit 0
fi

OEM_FILE="npcap-${LATEST}-oem.exe"
GCS_PATH="gs://${GCS_BUCKET}/private/${OEM_FILE}"

echo "--- Checking GCS bucket for existing artifact"

# Skip the download/upload if the artifact is already in the bucket (idempotent
# in case the pipeline is re-run or a previous upload partially succeeded).
if gcloud storage ls "$GCS_PATH" 2>/dev/null; then
  echo "Artifact already present: ${GCS_PATH}"
else
  echo "--- Downloading ${OEM_FILE} from npcap.com"

  # Read OEM credentials from Vault.
  # Path populated by: https://github.com/elastic/observability-github-secrets/pull/585
  NPCAP_USERNAME=$(vault kv get -field=data \
    "kv/ci-shared/observability-github-secrets/golang-crossbuild/NPCAP_USERNAME")
  NPCAP_PASSWORD=$(vault kv get -field=data \
    "kv/ci-shared/observability-github-secrets/golang-crossbuild/NPCAP_PASSWORD")

  retry 3 curl -fL -O --digest -u "${NPCAP_USERNAME}:${NPCAP_PASSWORD}" \
    "https://npcap.com/oem/dist/${OEM_FILE}"

  echo "--- Uploading to ${GCS_PATH}"
  gcloud storage cp "./${OEM_FILE}" "$GCS_PATH"
  rm "./${OEM_FILE}"
  echo "Upload complete."
fi

echo "--- Publishing version metadata for downstream steps"
buildkite-agent meta-data set "npcap-new-version" "${LATEST}"
buildkite-agent meta-data set "npcap-prev-version" "${CURRENT}"
buildkite-agent annotate \
  "New npcap version detected: **${CURRENT}** → **${LATEST}**" \
  --style "info" --context "npcap-version"
