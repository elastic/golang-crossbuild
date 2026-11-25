#!/usr/bin/env bash
# Manual check of the helpers in npcap-lib.sh against the real GitHub API and
# registry. Run with TEST_IMAGE_CHECK=1 in the golang-crossbuild-bump-npcap
# pipeline. Needs GITHUB_TOKEN and a docker login to docker.elastic.co.
set -uo pipefail

source "$(dirname "$0")/npcap-lib.sh"

status=0
pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*"; status=1; }

# Runs "$@" in a subshell (the helpers exit on unexpected errors) and checks
# the exit code and that nothing is printed to stderr.
expect() { # <expected rc> <description> <command...>
  local want=$1 desc=$2 err rc
  shift 2
  err=$(mktemp)
  ( "$@" ) 2> "$err"
  rc=$?
  if [ "$rc" -eq "$want" ] && [ ! -s "$err" ]; then
    pass "$desc (rc=${rc})"
  else
    fail "$desc: rc=${rc}, want ${want}; stderr: $(cat "$err")"
  fi
  rm -f "$err"
}

echo "--- gh CLI"
gh --version | head -1

echo "--- GitHub helpers"
expect 0 "branch_exists main" branch_exists main
expect 1 "branch_exists for a missing branch" branch_exists no-such-branch-for-test

main_npcap=$(npcap_version_at main)
main_go=$(go_version_at "$CROSSBUILD_REPO" main)
echo "main: Go ${main_go}, npcap ${main_npcap}"
[[ "$main_npcap" =~ ^[0-9]+\.[0-9]+$ ]] && pass "npcap_version_at main" || fail "npcap_version_at main: '${main_npcap}'"
[[ "$main_go" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && pass "go_version_at main" || fail "go_version_at main: '${main_go}'"

echo "--- Image check"
# The image of the Go version in .go-version of this checkout and the npcap
# version on main. Set TEST_IMAGE_GO and TEST_IMAGE_NPCAP to use another tag.
go_version="${TEST_IMAGE_GO:-$(tr -d '[:space:]' < .go-version)}"
npcap_version="${TEST_IMAGE_NPCAP:-$main_npcap}"
echo "published image under test: ${go_version}-npcap-${npcap_version}"
expect 0 "npcap_image_exists for a published image" npcap_image_exists "$go_version" "$npcap_version"
expect 1 "npcap_image_exists for a missing image" npcap_image_exists 0.0.0 0.0

exit "$status"
