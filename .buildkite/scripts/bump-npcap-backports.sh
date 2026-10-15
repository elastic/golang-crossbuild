#!/usr/bin/env bash
# Propagates the npcap version on main to the golang-crossbuild branches that
# build the Go versions used by the active elastic/beats branches, so that the
# golang-crossbuild:<go>-npcap-<version>-* images beats needs get published.
# This automates the manual steps described in NPCAP.md#backports.
#
# For each Go version X.Y.Z found in the .go-version of the active beats
# branches, the target branch in this repo is:
#   - main, if main builds X.Y.Z (already bumped by the main updatecli step)
#   - X.Y,  if the X.Y branch builds X.Y.Z
#   - X.Y.Z.x otherwise, created from the vX.Y.Z tag if it does not exist yet
# and a PR bumping NPCAP_VERSION is opened against it with updatecli.
#
# Nothing is propagated until the npcap bump PR on main has been merged, so
# a new npcap version is always reviewed on main first. The script is safe to
# re-run: targets already on the latest version are skipped, and updatecli
# reuses its existing PR for a target.
#
# Required environment:
#   GITHUB_TOKEN (exported by the elastic/vault-github-token Buildkite plugin)
# Optional environment:
#   DRY_RUN=1    print the targets without creating branches or PRs
set -euo pipefail

source "$(dirname "$0")/common.sh"

CROSSBUILD_REPO="elastic/golang-crossbuild"
BEATS_REPO="elastic/beats"
ACTIVE_BRANCHES_URL="https://storage.googleapis.com/artifacts-api/snapshots/branches.json"
UPDATECLI_CONFIG="${WORKSPACE}/.buildkite/updatecli.d/bump-npcap.yml"
UPDATECLI_VALUES="${WORKSPACE}/.buildkite/updatecli.d/values.d/scm.yml"
DRY_RUN="${DRY_RUN:-}"

github_api() {
  curl -sfL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" "$@"
}

# Prints the raw content of <path> in <repo> at <ref>.
file_at_ref() { # <repo> <path> <ref>
  github_api -H "Accept: application/vnd.github.raw" \
    "https://api.github.com/repos/$1/contents/$2?ref=$3"
}

# Returns 0 if <branch> exists in this repo, 1 if it does not, and exits on
# any other API error so a transient failure is not mistaken for "missing".
branch_exists() { # <branch>
  local status
  status=$(curl -sL -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "https://api.github.com/repos/${CROSSBUILD_REPO}/branches/$1")
  case "$status" in
    200) return 0 ;;
    404) return 1 ;;
    *) echo "ERROR: unexpected HTTP ${status} checking branch $1" >&2; exit 1 ;;
  esac
}

npcap_version_at() { # <ref>
  file_at_ref "$CROSSBUILD_REPO" Makefile.common "$1" | sed -n 's/^NPCAP_VERSION := //p'
}

go_version_at() { # <repo> <ref>
  file_at_ref "$1" .go-version "$2" | tr -d '[:space:]'
}

# Prints the branch building <go_version>: X.Y if it builds exactly that
# version, X.Y.Z.x otherwise (which may not exist yet, see ensure_branch).
target_branch_for() { # <go_version>
  local minor="${1%.*}"
  if branch_exists "$minor" && [ "$(go_version_at "$CROSSBUILD_REPO" "$minor")" = "$1" ]; then
    echo "$minor"
  else
    echo "${1}.x"
  fi
}

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
  tag_sha=$(github_api "https://api.github.com/repos/${CROSSBUILD_REPO}/commits/v$2" | jq -r .sha)
  if [ -n "$DRY_RUN" ]; then
    echo "[dry-run] would create branch $1 from v$2 (${tag_sha})"
    return 0
  fi
  echo "Creating branch $1 from v$2 (${tag_sha})"
  github_api -X POST "https://api.github.com/repos/${CROSSBUILD_REPO}/git/refs" \
    -d "{\"ref\": \"refs/heads/$1\", \"sha\": \"${tag_sha}\"}" > /dev/null
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

LATEST=$(retry 3 github_api https://api.github.com/repos/nmap/npcap/releases/latest \
  | jq -r .tag_name | sed 's/^v//')
MAIN_NPCAP=$(npcap_version_at main)
MAIN_GO=$(go_version_at "$CROSSBUILD_REPO" main)

echo "Latest npcap release: ${LATEST}"
echo "npcap on main:        ${MAIN_NPCAP} (Go ${MAIN_GO})"

if [ "$MAIN_NPCAP" != "$LATEST" ]; then
  echo "Waiting for the npcap ${LATEST} bump PR on main to be merged. Nothing to do."
  exit 0
fi

MAIN_PR_URL=$(github_api -G "https://api.github.com/search/issues" \
  --data-urlencode "q=repo:${CROSSBUILD_REPO} is:pr is:merged base:main in:title \"Bump npcap to version ${LATEST}\"" \
  | jq -r '.items[0].html_url // empty' || true)

echo "--- Collecting Go versions of the active elastic/beats branches"

BEATS_GO_VERSIONS=$(mktemp)
for beats_branch in $(retry 3 curl -sfL "$ACTIVE_BRANCHES_URL" | jq -r '.branches[]'); do
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
for go_version in $(cut -d' ' -f1 "$BEATS_GO_VERSIONS" | sort -uV); do
  beats_branches=$(awk -v v="$go_version" '$1 == v { print $2 }' "$BEATS_GO_VERSIONS" | paste -sd, - | sed 's/,/, /g')

  if [ "$go_version" = "$MAIN_GO" ]; then
    echo "Go ${go_version}: built by main, already on npcap ${LATEST}."
    continue
  fi

  target=$(target_branch_for "$go_version")
  current=$(npcap_version_for "$target" "$go_version")
  echo "Go ${go_version} (beats ${beats_branches}): branch ${target}, npcap ${current}"

  if [ "$current" = "$LATEST" ]; then
    SUMMARY+="* \`${target}\` (Go ${go_version}): already on npcap ${LATEST}"$'\n'
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
