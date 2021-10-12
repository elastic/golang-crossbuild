#!/usr/bin/env bash
set -ueo pipefail
set +x

GREN_GITHUB_TOKEN=${GREN_GITHUB_TOKEN:?"missing GREN_GITHUB_TOKEN"}

gren release --token="${GREN_GITHUB_TOKEN}" -c .grenrc.js --
