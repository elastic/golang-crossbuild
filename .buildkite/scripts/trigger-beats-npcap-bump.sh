#!/usr/bin/env bash
# Dynamically uploads a Buildkite trigger step that fires the beats-bump-npcap
# pipeline, passing the npcap version discovered by the npcap-check-upload step.
#
# The version is read from Buildkite metadata set by bump-npcap.sh.
set -euo pipefail

NEW_NPCAP_VERSION=$(buildkite-agent meta-data get "new-npcap-version")
echo "Triggering beats-bump-npcap for npcap ${NEW_NPCAP_VERSION}"

buildkite-agent pipeline upload <<YAML
steps:
  - trigger: beats-bump-npcap
    label: ":beats: Bump npcap ${NEW_NPCAP_VERSION} in elastic/beats"
    build:
      branch: main
      message: "Automated npcap bump to v${NEW_NPCAP_VERSION}"
      env:
        NEW_NPCAP_VERSION: "${NEW_NPCAP_VERSION}"
YAML
