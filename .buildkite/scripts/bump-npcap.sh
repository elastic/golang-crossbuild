#!/usr/bin/env bash
# Downloads the latest npcap OEM installer from npcap.com and uploads it to the
# private GCS bucket, if a newer version than what is pinned in Makefile.common
# is available. The follow-up Makefile.common bump runs as an independent
# updatecli step (see .github/updatecli.d/bump-npcap.yml) that re-derives the
# latest version itself, so no state needs to be passed between the two steps.
#
# Required environment:
#   NPCAP_USERNAME / NPCAP_PASSWORD (provided by the elastic/vault-secrets
#     Buildkite plugin, which also registers them with the log redactor)
#   gcloud authenticated via the elastic/oblt-google-auth Buildkite plugin
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
  retry 3 curl -fL -O --digest -u "${NPCAP_USERNAME}:${NPCAP_PASSWORD}" \
    "https://npcap.com/oem/dist/${OEM_FILE}"

  echo "--- Uploading to ${GCS_PATH}"
  gcloud storage cp "./${OEM_FILE}" "$GCS_PATH"
  rm "./${OEM_FILE}"
  echo "Upload complete."
fi

buildkite-agent annotate \
  "New npcap version detected: **${CURRENT}** → **${LATEST}**" \
  --style "info" --context "npcap-version"
