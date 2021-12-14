#!/usr/bin/env bash
set -ueo pipefail
set +x

GREN_GITHUB_TOKEN=${GREN_GITHUB_TOKEN:?"missing GREN_GITHUB_TOKEN"}

gren changelog --token="${GREN_GITHUB_TOKEN}" --generate --override -c .grenrc.js
