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
# in case the pipeline is re-run after a failure). The ls check is safe: gcloud
# storage cp uses resumable uploads by default, which only make an object visible
# after a successful completion — a partial/interrupted upload leaves no
# addressable object behind. Parallel composite upload (which can leave temporary
# component objects visible) only triggers for large files; the npcap installer
# is ~1–2 MB, well below any composite-upload threshold. Upload integrity is
# verified via MD5 before the local copy is removed, so a present object can be
# trusted on re-runs.
if gcloud storage ls "$GCS_PATH" 2>/dev/null; then
  echo "Artifact already present: ${GCS_PATH}"
else
  echo "--- Downloading ${OEM_FILE} from npcap.com"
  retry 3 curl -fL -O --digest -u "${NPCAP_USERNAME}:${NPCAP_PASSWORD}" \
    "https://npcap.com/oem/dist/${OEM_FILE}"

  echo "--- Verifying download"
  file_type=$(file --brief "${OEM_FILE}")
  echo "File type: ${file_type}"
  if ! grep -q "PE32" <<< "${file_type}"; then
    echo "ERROR: expected a PE32 executable, got: ${file_type}"
    exit 1
  fi

  LOCAL_MD5=$(md5sum "./${OEM_FILE}" | awk '{print $1}')
  echo "MD5 (local): ${LOCAL_MD5}"

  echo "--- Uploading to ${GCS_PATH}"
  gcloud storage cp "./${OEM_FILE}" "$GCS_PATH"
  rm "./${OEM_FILE}"

  echo "--- Verifying upload integrity"
  # GCS records an MD5 in object metadata computed at ingest time. Retrieve it
  # without re-downloading the file and compare it against the local hash to
  # confirm the stored object is byte-for-byte identical to what was fetched
  # from npcap.com. On mismatch, remove the object so a re-run can retry cleanly.
  GCS_MD5=$(gcloud storage hash --hex "$GCS_PATH" | awk '/^md5_hash:/{print $2}')
  echo "MD5 (GCS):   ${GCS_MD5}"
  if [ "$LOCAL_MD5" != "$GCS_MD5" ]; then
    echo "ERROR: MD5 mismatch — the uploaded object may be corrupt."
    echo "  Local: ${LOCAL_MD5}"
    echo "  GCS:   ${GCS_MD5}"
    gcloud storage rm "$GCS_PATH" 2>/dev/null || true
    exit 1
  fi
  echo "Upload integrity verified (MD5 ${LOCAL_MD5})."
fi

buildkite-agent annotate \
  "New npcap version detected: **${CURRENT}** → **${LATEST}**" \
  --style "info" --context "npcap-version"
