#!/usr/bin/env bash
# Propagates the npcap version on main to the golang-crossbuild branches that
# build the Go versions used by the active elastic/beats branches, so that the
# golang-crossbuild:<go>-npcap-<version>-* images beats needs get published.
# This automates the manual steps described in NPCAP.md#backports.
#
# Beats reads NPCAP_VERSION from the X.Y branch of this repo (or from main if
# there is no X.Y branch), and then requires the image
# <X.Y.Z>-npcap-<version>-debian9 for its own Go version X.Y.Z. So for the
# Go versions X.Y.Z found in the .go-version of the active beats branches:
#   1. The X.Y branch is bumped if it exists, even when it builds another patch
#      version, because that is the version beats reads.
#   2. The image of X.Y.Z must exist. If it is not published and no X.Y branch
#      builds X.Y.Z, the X.Y.Z.x branch is bumped, created from the vX.Y.Z tag
#      if it does not exist yet. main already builds its own Go version.
# A PR bumping NPCAP_VERSION is opened against each branch with updatecli.
#
# Nothing is propagated until the npcap bump PR on main has been merged, so
# a new npcap version is always reviewed on main first. The script is safe to
# re-run: branches already on the latest version are skipped, and updatecli
# reuses its existing PR for a branch.
#
# Required environment:
#   GITHUB_TOKEN (exported by the elastic/vault-github-token Buildkite plugin,
#                 read by the gh CLI)
#   docker login to docker.elastic.co (elastic/vault-docker-login Buildkite plugin)
# Optional environment:
#   DRY_RUN=1    print the targets without creating branches or PRs
set -euo pipefail

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/npcap-lib.sh"

BEATS_REPO="elastic/beats"
ACTIVE_BRANCHES_URL="https://storage.googleapis.com/artifacts-api/snapshots/branches.json"
UPDATECLI_CONFIG="${WORKSPACE}/.buildkite/updatecli.d/bump-npcap.yml"
UPDATECLI_VALUES="${WORKSPACE}/.buildkite/updatecli.d/values.d/scm.yml"
DRY_RUN="${DRY_RUN:-}"

# Prints the npcap version of <branch>, or of the v<go_version> tag it would
# be created from if it does not exist yet.
npcap_version_for() { # <branch> <go_version>
  if branch_exists "$1"; then
    npcap_version_at "$1"
  else
    npcap_version_at "v$2"
  fi
}

# Creates <branch> from the v<go_version> tag. An existing branch is reused.
ensure_branch() { # <branch> <go_version>
  if branch_exists "$1"; then
    return 0
  fi
  local tag_sha
  tag_sha=$(gh api "repos/${CROSSBUILD_REPO}/commits/v$2" --jq .sha)
  if [ -n "$DRY_RUN" ]; then
    echo "[dry-run] would create branch $1 from v$2 (${tag_sha})"
    return 0
  fi
  echo "Creating branch $1 from v$2 (${tag_sha})"
  gh api -X POST "repos/${CROSSBUILD_REPO}/git/refs" \
    -f ref="refs/heads/$1" -f sha="${tag_sha}" > /dev/null
}

# Opens, or updates, the updatecli PR bumping NPCAP_VERSION on <branch>.
open_bump_pr() { # <branch> <go_version> <beats_branches>
  local values="${VALUES_DIR}/$1.yml"
  cat > "$values" <<EOF
scm:
  branch: "$1"
backport:
  note: "Backport of ${MAIN_PR_URL:-the npcap ${LATEST} bump on main} for Go $2, used by the elastic/beats branches: $3."
EOF
  if [ -n "$DRY_RUN" ]; then
    echo "[dry-run] would run updatecli against $1 with:"
    cat "$values"
  else
    # Later --values files override earlier ones (deep merge), so scm.branch
    # from $values wins over scm.yml. Keep scm.yml first.
    "$(dirname "$0")/run-updatecli.sh" "$UPDATECLI_CONFIG" --values "$UPDATECLI_VALUES" --values "$values"
  fi
}

echo "--- Checking npcap version on main"

LATEST=$(retry 3 gh api repos/nmap/npcap/releases/latest --jq .tag_name | sed 's/^v//')
MAIN_NPCAP=$(npcap_version_at main)
MAIN_GO=$(go_version_at "$CROSSBUILD_REPO" main)

echo "Latest npcap release: ${LATEST}"
echo "npcap on main:        ${MAIN_NPCAP} (Go ${MAIN_GO})"

if [ "$MAIN_NPCAP" != "$LATEST" ]; then
  echo "Waiting for the npcap ${LATEST} bump PR on main to be merged. Nothing to do."
  exit 0
fi

MAIN_PR_URL=$(gh api -X GET search/issues \
  -f q="repo:${CROSSBUILD_REPO} is:pr is:merged base:main in:title \"Bump npcap to version ${LATEST}\"" \
  --jq '.items[0].html_url // empty' || true)

echo "--- Collecting Go versions of the active elastic/beats branches"

BEATS_GO_VERSIONS=$(mktemp)
# Assign first: a failure inside a command substitution in a for list is ignored.
BEATS_BRANCHES=$(retry 3 curl -sfL "$ACTIVE_BRANCHES_URL" | jq -r '.branches[]')
if [ -z "$BEATS_BRANCHES" ]; then
  echo "ERROR: no active beats branches found at ${ACTIVE_BRANCHES_URL}" >&2
  exit 1
fi
for beats_branch in $BEATS_BRANCHES; do
  go_version=$(go_version_at "$BEATS_REPO" "$beats_branch")
  if ! [[ "$go_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: unexpected .go-version '${go_version}' on ${BEATS_REPO}@${beats_branch}" >&2
    exit 1
  fi
  echo "${BEATS_REPO}@${beats_branch}: Go ${go_version}"
  echo "${go_version} ${beats_branch}" >> "$BEATS_GO_VERSIONS"
done

echo "--- Reconciling npcap ${LATEST} on the golang-crossbuild branches"

VALUES_DIR=$(mktemp -d)
SUMMARY=""

# 1. The X.Y branches, which are the npcap version that beats reads.
for minor in $(cut -d' ' -f1 "$BEATS_GO_VERSIONS" | cut -d. -f1,2 | sort -uV); do
  beats_branches=$(awk -v m="$minor" '{ split($1, v, "."); if (v[1] "." v[2] == m) print $2 }' "$BEATS_GO_VERSIONS" \
    | paste -sd, - | sed 's/,/, /g')

  if ! branch_exists "$minor"; then
    echo "Go ${minor} (beats ${beats_branches}): no ${minor} branch, beats reads main."
    continue
  fi

  current=$(npcap_version_at "$minor")
  echo "Go ${minor} (beats ${beats_branches}): branch ${minor}, npcap ${current}"
  if [ "$current" = "$LATEST" ]; then
    SUMMARY+="* \`${minor}\`: already on npcap ${LATEST}"$'\n'
    continue
  fi

  open_bump_pr "$minor" "$minor" "$beats_branches"
  SUMMARY+="* \`${minor}\`: npcap ${current} → ${LATEST} PR opened or updated"$'\n'
done

# 2. The image of each Go version that beats uses.
for go_version in $(cut -d' ' -f1 "$BEATS_GO_VERSIONS" | sort -uV); do
  minor="${go_version%.*}"
  beats_branches=$(awk -v v="$go_version" '$1 == v { print $2 }' "$BEATS_GO_VERSIONS" | paste -sd, - | sed 's/,/, /g')

  if [ "$go_version" = "$MAIN_GO" ]; then
    echo "Go ${go_version}: built by main, already on npcap ${LATEST}."
    continue
  fi

  if npcap_image_exists "$go_version" "$LATEST"; then
    SUMMARY+="* Go ${go_version}: image npcap ${LATEST} already published"$'\n'
    echo "Go ${go_version}: image npcap ${LATEST} already published."
    continue
  fi

  if branch_exists "$minor" && [ "$(go_version_at "$CROSSBUILD_REPO" "$minor")" = "$go_version" ]; then
    SUMMARY+="* Go ${go_version}: image npcap ${LATEST} not published yet, built by \`${minor}\`"$'\n'
    echo "Go ${go_version}: image not published yet, it is built by ${minor}."
    continue
  fi

  target="${go_version}.x"
  current=$(npcap_version_for "$target" "$go_version")
  echo "Go ${go_version} (beats ${beats_branches}): branch ${target}, npcap ${current}"

  if [ "$current" = "$LATEST" ]; then
    SUMMARY+="* \`${target}\` (Go ${go_version}): on npcap ${LATEST}, image not published yet"$'\n'
    continue
  fi

  ensure_branch "$target" "$go_version"
  open_bump_pr "$target" "$go_version" "$beats_branches"
  SUMMARY+="* \`${target}\` (Go ${go_version}): npcap ${current} → ${LATEST} PR opened or updated"$'\n'
done

if [ -n "$SUMMARY" ] && [ -z "$DRY_RUN" ] && command -v buildkite-agent > /dev/null; then
  buildkite-agent annotate "npcap ${LATEST} backports:"$'\n\n'"${SUMMARY}" \
    --style "info" --context "npcap-backports"
fi
